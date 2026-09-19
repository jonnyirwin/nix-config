"""Emit a battery estimate as JSON for Status.qml, for when the fuel gauge
stops updating.

A worn pack's gauge can freeze: energy_now sticks at energy_full ("100%")
while the machine discharges at ~10 W until it cuts out with no warning.
power_now and voltage_now keep updating live, so while the gauge is frozen
this counts energy down from the last value it reported, integrating
power_now between calls. The running total lives in $XDG_STATE_HOME so a
restart of the shell (it restarts after every resume) doesn't reset it to
the frozen "100%".

Polled every 30s: `quickshell-battery-status | jq`.
"""
import glob
import json
import os
import sys
import time

SYS = "/sys/class/power_supply"
# Gauge unchanged this long while discharging => treat it as frozen.
STALE_AFTER = 180
# A gap between calls longer than this is a suspend (or the shell was
# down); count it at a suspend-ish draw rather than the last live reading.
MAX_GAP = 180
SUSPEND_UW = 500_000
# Below this per-cell voltage under load a Li-ion pack is nearly empty,
# whatever the gauge claims.
CRITICAL_CELL_V = 3.45


def state_path():
    base = os.environ.get(
        "XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
    return os.path.join(base, "quickshell-battery.json")


def read(path, key, default=0):
    try:
        with open(os.path.join(path, key)) as f:
            return f.read().strip()
    except OSError:
        return default


def battery():
    for path in sorted(glob.glob(os.path.join(SYS, "BAT*"))):
        if read(path, "present", "0") != "1":
            continue
        full = int(read(path, "energy_full"))
        if full <= 0:
            continue
        return {
            "status": read(path, "status", "Unknown"),
            "now": int(read(path, "energy_now")),
            "full": full,
            "power": abs(int(read(path, "power_now"))),
            "volt": int(read(path, "voltage_now")),
            "volt_design": int(read(path, "voltage_min_design")),
        }
    return None


def load_state():
    try:
        with open(state_path()) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def save_state(state):
    path = state_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, path)


def main():
    bat = battery()
    if bat is None:
        return 1
    now = time.time()
    state = load_state()

    fresh = (
        state is None
        or bat["status"] != "Discharging"
        or state.get("energy") != bat["now"]
    )
    if fresh:
        state = {"energy": bat["now"], "changed_at": now, "used": 0}
    else:
        dt = max(0.0, now - state.get("last_ts", now))
        uw = bat["power"] if dt <= MAX_GAP else SUSPEND_UW
        state["used"] += uw * dt / 3600
    state["last_ts"] = now
    save_state(state)

    stale = (
        bat["status"] == "Discharging"
        and now - state["changed_at"] >= STALE_AFTER
        and state["used"] > 0
    )
    energy = max(0.0, bat["now"] - state["used"]) if stale else bat["now"]
    percent = round(min(100.0, 100 * energy / bat["full"]))

    cells = max(1, round(bat["volt_design"] / 3.7e6))
    cell_v = bat["volt"] / 1e6 / cells
    low_voltage = bat["status"] == "Discharging" and cell_v < CRITICAL_CELL_V

    json.dump({
        "percent": percent,
        "estimated": stale,
        "lowVoltage": low_voltage,
        "cellVoltage": round(cell_v, 3),
    }, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
