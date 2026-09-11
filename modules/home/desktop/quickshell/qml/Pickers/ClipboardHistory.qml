import QtQuick
import Quickshell
import Quickshell.Io
import qs.Widgets

// Replaces the clipboard-history keybinding (cliphist list | rofi -dmenu |
// cliphist decode | wl-copy). The selected line has to go back into
// `cliphist decode` byte-for-byte, including whatever's in the clipboard
// text itself — passed through an env var rather than interpolated into
// the shell string, so nothing in the clipboard can break out of it.
PickerWindow {
    id: root

    namespaceSuffix: "clipboard-history"
    title: "Clipboard History"
    placeholder: "Filter…"

    IpcHandler {
        target: "clipboardHistory"
        function open() { root.open(); }
        function close() { root.close(); }
        function toggle() { root.toggle(); }
    }

    onAboutToOpen: fetchProc.running = true
    onActivated: (item) => {
        decodeProc.environment = { "CLIP_LINE": item.key };
        decodeProc.running = true;
    }

    Process {
        id: fetchProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "");
                root.items = lines.map(line => ({
                    "key": line,
                    "label": line.replace(/^\S+\s*/, "").slice(0, 90)
                }));
            }
        }
    }

    Process {
        id: decodeProc
        command: ["sh", "-c", "printf '%s' \"$CLIP_LINE\" | cliphist decode | wl-copy"]
    }
}
