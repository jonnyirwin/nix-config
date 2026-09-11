pragma Singleton
import QtQuick
import Quickshell
import Quickshell.I3

// Thin wrapper over Quickshell's I3 IPC client — sway speaks the i3ipc
// protocol, so this is the real sway integration, not a swaymsg-shelling
// stand-in. Kept as its own singleton (rather than reaching for `I3` inline
// everywhere) so Bar.qml doesn't need to know that detail.
Singleton {
    id: root

    function forOutput(outputName) {
        const all = (I3.workspaces && I3.workspaces.values) || [];
        if (!outputName)
            return all.slice().sort((a, b) => a.number - b.number);
        return all
            .filter(ws => !ws.monitor || ws.monitor.name === outputName)
            .sort((a, b) => a.number - b.number);
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
}
