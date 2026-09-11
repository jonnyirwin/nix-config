pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris

// Everything the bar/OSD/control-centre show about the machine's state.
// Audio and battery are read live off Pipewire/UPower — Quickshell's native
// services, not a shelled-out poll. Brightness, network, idle-inhibit,
// backup and pomodoro have no such service, so those reuse the exact
// helper scripts waybar's custom modules already call (modules/home/desktop/
// scripts.nix, modules/home/backup.nix) — one source of truth either bar
// reads from.
Singleton {
    id: root

    // Bound to the sway keybinding that used to killall -SIGUSR1 waybar
    // (jonny.desktop.keys.toggleBar) — see the "bar" IpcHandler in shell.qml.
    property bool barVisible: true
    function toggleBar() { root.barVisible = !root.barVisible; }

    // ---- Media (Mpris) — the bar's centre island morphs to this when
    // something is playing, ahead of falling back to the pomodoro ring. ----
    readonly property var _players: Mpris.players.values
    readonly property MprisPlayer activePlayer: {
        const playing = root._players.find(p => p.playbackState === MprisPlaybackState.Playing);
        if (playing)
            return playing;
        return root._players.length > 0 ? root._players[0] : null;
    }
    readonly property bool mediaAvailable: !!root.activePlayer
    readonly property bool mediaPlaying: root.mediaAvailable && root.activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property string mediaTitle: root.activePlayer?.trackTitle || ""
    readonly property string mediaArtist: root.activePlayer?.trackArtist || ""
    readonly property string mediaArtUrl: root.activePlayer?.trackArtUrl || ""

    function mediaTogglePlaying() {
        const p = root.activePlayer;
        if (!p || !p.canControl)
            return;
        // togglePlaying() exists on some players and not others depending on
        // MPRIS backend — fall back to explicit play/pause either way.
        if (typeof p.togglePlaying === "function") {
            p.togglePlaying();
        } else if (root.mediaPlaying && p.canPause) {
            p.pause();
        } else if (!root.mediaPlaying && p.canPlay) {
            p.play();
        }
    }
    function mediaNext() {
        if (root.activePlayer && root.activePlayer.canGoNext)
            root.activePlayer.next();
    }
    function mediaPrevious() {
        if (root.activePlayer && root.activePlayer.canGoPrevious)
            root.activePlayer.previous();
    }

    // ---- Audio (Pipewire) ----
    readonly property PwNode _sink: Pipewire.defaultAudioSink
    readonly property bool volumeAvailable: !!(root._sink && root._sink.audio)
    readonly property int volume: root.volumeAvailable ? Math.round(root._sink.audio.volume * 100) : 0
    readonly property bool muted: root.volumeAvailable && root._sink.audio.muted

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(n => n)
    }

    function setVolume(pct) {
        if (!root.volumeAvailable)
            return;
        root._sink.audio.muted = false;
        root._sink.audio.volume = Math.max(0, Math.min(100, pct)) / 100;
    }

    function stepVolume(delta) {
        root.setVolume(root.volume + delta);
    }

    function toggleMute() {
        if (root.volumeAvailable)
            root._sink.audio.muted = !root._sink.audio.muted;
    }

    // ---- Battery (UPower) ----
    readonly property var _batteries: UPower.devices.values.filter(d => d.isLaptopBattery && d.ready)
    readonly property bool hasBattery: root._batteries.length > 0
    readonly property var _battery: root.hasBattery ? root._batteries[0] : null
    readonly property int batteryPercent: root._battery ? Math.round(root._battery.percentage * 100) : 0
    readonly property bool batteryCharging: root._battery ? root._battery.state === UPowerDeviceState.Charging : false
    readonly property string batteryState: {
        if (!root.hasBattery)
            return "none";
        if (root.batteryCharging)
            return "charging";
        if (root.batteryPercent <= 15)
            return "critical";
        if (root.batteryPercent <= 30)
            return "warning";
        return "normal";
    }

    // ---- Brightness (DDC/CI or backlight — see scripts.nix `brightness`) ----
    property bool brightnessAvailable: false
    property int brightnessPercent: 0

    function brightnessUp() {
        brightnessProc.command = ["brightness", "up"];
        brightnessProc.running = true;
    }

    function brightnessDown() {
        brightnessProc.command = ["brightness", "down"];
        brightnessProc.running = true;
    }

    // For the bar's drag-slider: the `brightness` script only steps
    // relatively (no absolute set), but it does take an explicit step size
    // as a second argument — so an "absolute set" is just one step of
    // exactly the right size in the right direction.
    //
    // Called once per interaction (SliderPill previews the drag locally and
    // only commits on release) rather than per pointer move — an earlier
    // version called this continuously and debounced it here instead, but
    // debouncing the *calls* doesn't help when each one can itself take the
    // better part of a second over DDC/CI (see scripts.nix's own comment on
    // `brightness`); previewing locally and committing once sidesteps that
    // hardware latency instead of trying to outrun it.
    function setBrightness(target) {
        if (!root.brightnessAvailable)
            return;
        const delta = Math.round(target) - root.brightnessPercent;
        if (delta === 0)
            return;
        brightnessProc.command = ["brightness", delta > 0 ? "up" : "down", String(Math.abs(delta))];
        brightnessProc.running = true;
    }

    Process {
        id: brightnessProc
        onExited: brightnessPollTimer.triggered()
    }

    Timer {
        id: brightnessPollTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: brightnessPoll.running = true
    }

    Process {
        id: brightnessPoll
        command: ["brightness-status"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!text || text.trim() === "") {
                    root.brightnessAvailable = false;
                    return;
                }
                try {
                    const data = JSON.parse(text);
                    root.brightnessAvailable = true;
                    root.brightnessPercent = Math.round(data.percentage ?? 0);
                } catch (e) {
                    root.brightnessAvailable = false;
                }
            }
        }
    }

    // ---- Network ----
    property string networkIcon: "󰤭"
    property string networkTooltip: ""
    property string networkClass: "disconnected"

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: networkPoll.running = true
    }

    Process {
        id: networkPoll
        command: ["quickshell-network-status"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.networkIcon = data.icon || "󰤭";
                    root.networkTooltip = data.tooltip || "";
                    root.networkClass = data.state || "disconnected";
                } catch (e) {
                    // leave the last known state on screen
                }
            }
        }
    }

    // ---- Idle inhibitor ----
    property bool idleInhibited: false

    function toggleIdleInhibitor() {
        idleToggleProc.running = true;
    }

    Process {
        id: idleToggleProc
        command: ["idle-inhibitor-toggle"]
        onExited: idlePoll.running = true
    }

    // idle-inhibitor-toggle (scripts.nix) pings this after every toggle —
    // same job as its `pkill -RTMIN+10 waybar`, for the case that changed
    // the state without going through toggleIdleInhibitor() above (the sway
    // keybinding runs the script directly), which otherwise waited for the
    // next 3s poll below to notice.
    IpcHandler {
        target: "status"
        function refreshIdle() { idlePoll.running = true; }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: idlePoll.running = true
    }

    Process {
        id: idlePoll
        command: ["idle-inhibitor-status"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.idleInhibited = JSON.parse(text).class === "active";
                } catch (e) {
                    // unchanged
                }
            }
        }
    }

    // ---- Backup (modules/home/backup.nix) ----
    property bool backupEnabled: false
    property string backupText: ""
    property string backupClass: "idle"
    property string backupTooltip: ""

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: backupPoll.running = true
    }

    Process {
        id: backupPoll
        command: ["backup-status"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!text || text.trim() === "") {
                    root.backupEnabled = false;
                    return;
                }
                try {
                    const data = JSON.parse(text);
                    root.backupEnabled = true;
                    root.backupText = data.text || "";
                    root.backupClass = data.class || "idle";
                    root.backupTooltip = data.tooltip || "";
                } catch (e) {
                    root.backupEnabled = false;
                }
            }
        }
        onExited: (code) => {
            if (code !== 0)
                root.backupEnabled = false;
        }
    }

    // ---- Pomodoro ----
    property bool pomodoroEnabled: false
    property string pomodoroText: ""
    property string pomodoroClass: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pomodoroPoll.running = true
    }

    Process {
        id: pomodoroPoll
        command: ["pomodoro", "display"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!text || text.trim() === "") {
                    root.pomodoroEnabled = false;
                    return;
                }
                try {
                    const data = JSON.parse(text);
                    root.pomodoroEnabled = true;
                    root.pomodoroText = data.text || "";
                    root.pomodoroClass = data.class || "";
                } catch (e) {
                    root.pomodoroEnabled = false;
                }
            }
        }
        onExited: (code) => {
            if (code !== 0)
                root.pomodoroEnabled = false;
        }
    }
}
