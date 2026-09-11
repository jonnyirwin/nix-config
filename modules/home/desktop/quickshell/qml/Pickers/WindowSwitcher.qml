import QtQuick
import Quickshell
import Quickshell.Io
import qs.Widgets

// Replaces scripts.nix's window-switcher (swaymsg get_tree | jq | rofi
// -dmenu). Parses the tree in JS instead of shelling to jq — same data,
// one less layer of shell-quoting to get wrong.
PickerWindow {
    id: root

    namespaceSuffix: "window-switcher"
    title: "Windows"
    placeholder: "Filter windows…"

    onAboutToOpen: fetchProc.running = true
    onActivated: (item) => Quickshell.execDetached(["swaymsg", `[con_id=${item.key}] focus`])

    IpcHandler {
        target: "windowSwitcher"
        function open() { root.open(); }
        function close() { root.close(); }
        function toggle() { root.toggle(); }
    }

    function walk(node, out) {
        if (!node)
            return;
        if (node.pid && node.name) {
            out.push({
                "key": String(node.id),
                "label": node.name,
                "sublabel": node.app_id || (node.window_properties && node.window_properties.class) || "unknown"
            });
        }
        (node.nodes || []).forEach(n => walk(n, out));
        (node.floating_nodes || []).forEach(n => walk(n, out));
    }

    Process {
        id: fetchProc
        command: ["swaymsg", "-t", "get_tree"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const out = [];
                    root.walk(JSON.parse(text), out);
                    root.items = out;
                } catch (e) {
                    root.items = [];
                }
            }
        }
    }
}
