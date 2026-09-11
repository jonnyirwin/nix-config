pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Desktop-entry launcher backend — the replacement for rofi's drun mode.
// The actual .desktop parsing lives in quickshell-list-apps (a small script
// generated alongside this shell, see modules/home/desktop/quickshell/
// default.nix) so it can be tested and iterated on without recompiling QML.
Singleton {
    id: root

    property var entries: []
    property bool loaded: false

    function refresh() {
        listProc.running = true;
    }

    Process {
        id: listProc
        command: ["quickshell-list-apps"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.entries = JSON.parse(text);
                } catch (e) {
                    root.entries = [];
                }
                root.loaded = true;
            }
        }
    }

    function search(query) {
        const q = String(query || "").toLowerCase().trim();
        if (q === "")
            return root.entries;
        return root.entries.filter(e => e.name.toLowerCase().includes(q) || (e.comment && e.comment.toLowerCase().includes(q)));
    }

    function launch(entry) {
        if (!entry || !entry.exec)
            return;
        Quickshell.execDetached(["sh", "-c", entry.exec]);
    }

    Component.onCompleted: refresh()
}
