import QtQuick
import Quickshell
import Quickshell.Io
import qs.Widgets

// Replaces scripts.nix's screen-rotate (a static rofi -dmenu list).
PickerWindow {
    id: root

    namespaceSuffix: "screen-rotate"
    title: "Rotate Screen"
    searchEnabled: false
    panelWidth: 320
    panelHeight: 260

    items: [
        { "key": "normal", "label": "Landscape" },
        { "key": "90", "label": "Portrait (right)" },
        { "key": "180", "label": "Landscape (flipped)" },
        { "key": "270", "label": "Portrait (left)" }
    ]

    property string pendingTransform: ""

    IpcHandler {
        target: "screenRotate"
        function open() { root.open(); }
        function close() { root.close(); }
        function toggle() { root.toggle(); }
    }

    onActivated: (item) => {
        root.pendingTransform = item.key;
        findOutputProc.running = true;
    }

    Process {
        id: findOutputProc
        command: ["swaymsg", "-t", "get_outputs"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const outputs = JSON.parse(text);
                    const target = outputs.find(o => o.focused) || outputs.find(o => o.active);
                    if (target)
                        Quickshell.execDetached(["swaymsg", "output", target.name, "transform", root.pendingTransform]);
                } catch (e) {
                    // no active output found — nothing sensible to rotate
                }
            }
        }
    }
}
