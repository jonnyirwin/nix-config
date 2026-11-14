pragma Singleton
import QtQuick
import Quickshell
import Quickshell.I3

// Thin wrapper over Quickshell's I3 IPC client — sway speaks the i3ipc
// protocol, so this is the real sway integration, not a swaymsg-shelling
// stand-in. Kept as its own singleton (rather than reaching for `I3` inline
// everywhere) so Bar.qml doesn't need to know that detail.
//
// Updates are event-driven (instant). Don't go back to polling `swaymsg`:
// spawning a process every second made clicks feel laggy, and its JSON uses
// `num` rather than `number`, which silently broke sorting (4, 1, 2, 3).
Singleton {
    id: root

    function sortKey(ws) {
        return (ws.number !== undefined && ws.number >= 0) ? ws.number : 1e6;
    }

    function byNumber(a, b) {
        return root.sortKey(a) - root.sortKey(b) || String(a.name).localeCompare(String(b.name));
    }

    function forOutput(outputName) {
        const all = ((I3.workspaces && I3.workspaces.values) || []).slice();
        if (!outputName)
            return all.sort(root.byNumber);
        const mine = all.filter(ws => !ws.monitor || ws.monitor.name === outputName);
        // After an output hotplug, monitor refs can briefly go stale and match
        // nothing — show everything rather than an empty bar.
        return (mine.length ? mine : all).sort(root.byNumber);
    }

    function activate(ws) {
        if (!ws)
            return;
        if (ws.number !== undefined && ws.number !== -1) {
            I3.dispatch(`workspace number ${ws.number}`);
            return;
        }
        if (ws.name) {
            const escaped = String(ws.name).replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
            I3.dispatch(`workspace "${escaped}"`);
        }
    }

    // Self-heal: if an IPC event is ever missed (output hotplug, resume),
    // resync from sway over the existing socket. This is a single in-process
    // IPC request, not a subprocess, and updates existing objects in place.
    Connections {
        target: I3
        function onRawEvent(event) {
            if (event.type === "output") {
                I3.refreshMonitors();
                I3.refreshWorkspaces();
            }
        }
        function onConnected() {
            I3.refreshMonitors();
            I3.refreshWorkspaces();
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: I3.refreshWorkspaces()
    }
}
