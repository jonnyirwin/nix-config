import QtQuick
import Quickshell
import Quickshell.Io
import qs.Widgets

// Replaces scripts.nix's network-menu (nmcli piped into rofi -dmenu).
PickerWindow {
    id: root

    namespaceSuffix: "network-menu"
    title: "Network"
    placeholder: "Filter networks…"

    property bool wifiEnabled: false
    property string connectedSsid: ""

    onAboutToOpen: fetchProc.running = true

    IpcHandler {
        target: "networkMenu"
        function open() { root.open(); }
        function close() { root.close(); }
        function toggle() { root.toggle(); }
    }

    onActivated: (item) => {
        if (item.key === "__toggle__") {
            Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]);
        } else if (item.key === "__manage__") {
            Quickshell.execDetached(["nm-connection-editor"]);
        } else if (item.key.startsWith("disconnect:")) {
            Quickshell.execDetached(["nmcli", "connection", "down", item.key.slice("disconnect:".length)]);
        } else if (item.key.startsWith("connect:")) {
            // nm-applet (started from sway's startup block) answers the
            // passphrase prompt as NetworkManager's secret agent — same as
            // the rofi version, no password handling needed here either.
            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", item.key.slice("connect:".length)]);
        }
    }

    Process {
        id: fetchProc
        command: ["sh", "-c", "nmcli -t radio wifi; echo ---; nmcli -t -f NAME connection show --active; echo ---; nmcli -t -f SSID,SIGNAL dev wifi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const sections = text.split("---\n");
                const wifiStatus = (sections[0] || "").trim();
                const activeConn = (sections[1] || "").trim();
                const wifiLines = (sections[2] || "").split("\n").map(l => l.trim()).filter(l => l !== "");

                root.wifiEnabled = wifiStatus === "enabled";

                const out = [{
                    "key": "__toggle__",
                    "icon": root.wifiEnabled ? "󰤨" : "󰤭",
                    "label": root.wifiEnabled ? "Turn Wi-Fi off" : "Turn Wi-Fi on"
                }];

                if (root.wifiEnabled) {
                    const seen = new Set();
                    for (const line of wifiLines) {
                        const idx = line.lastIndexOf(":");
                        if (idx < 0)
                            continue;
                        const ssid = line.slice(0, idx);
                        const signal = line.slice(idx + 1);
                        if (!ssid || seen.has(ssid))
                            continue;
                        seen.add(ssid);
                        const connected = ssid === activeConn;
                        out.push({
                            "key": connected ? `disconnect:${ssid}` : `connect:${ssid}`,
                            "icon": connected ? "󰒓" : "󰒕",
                            "label": ssid,
                            "sublabel": connected ? `Connected · ${signal}%` : `${signal}%`
                        });
                    }
                }

                out.push({ "key": "__manage__", "icon": "󰒓", "label": "Manage connections…" });
                root.items = out;
            }
        }
    }
}
