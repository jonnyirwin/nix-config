pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Sway's IPC event stream can occasionally stop updating in Quickshell while
// the compositor remains healthy. Refresh the small workspace list from
// swaymsg periodically so the bar recovers without restarting the shell.
Singleton {
    id: root

    property var workspaces: []

    function refresh() {
        if (!workspaceProc.running)
            workspaceProc.running = true;
    }

    function forOutput(outputName) {
        const all = root.workspaces;
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
            Quickshell.execDetached(["swaymsg", `workspace number ${ws.number}`]);
            return;
        }
        if (ws.name) {
            const escaped = String(ws.name).replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
            Quickshell.execDetached(["swaymsg", `workspace "${escaped}"`]);
        }
    }

    Process {
        id: workspaceProc
        command: ["swaymsg", "-t", "get_workspaces"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const next = JSON.parse(text);
                    if (Array.isArray(next))
                        root.workspaces = next;
                } catch (e) {
                    // Keep the last good snapshot if swaymsg is temporarily
                    // unavailable or returns incomplete output.
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
