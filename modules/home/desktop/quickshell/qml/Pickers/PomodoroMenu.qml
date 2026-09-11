import QtQuick
import Quickshell
import Quickshell.Io
import qs.Widgets

// Replaces pomodoro-menu.sh's rofi list. Doesn't show the configured
// work/break minute counts in the labels the way the bash version did —
// those come from jonny.desktop.pomodoro.* via a sourced config file, which
// isn't something this file can read; worth generating a small data file
// for if that detail earns its keep back.
PickerWindow {
    id: root

    namespaceSuffix: "pomodoro-menu"
    title: "Pomodoro"
    searchEnabled: false
    panelWidth: 320
    panelHeight: 320

    items: [
        { "key": "start", "icon": "🍅", "label": "Start Work" },
        { "key": "short-break", "icon": "☕", "label": "Short Break" },
        { "key": "long-break", "icon": "☕", "label": "Long Break" },
        { "key": "toggle", "icon": "⏸", "label": "Toggle Pause/Resume" },
        { "key": "stop", "icon": "⏹", "label": "Stop Timer" },
        { "key": "skip-break", "icon": "🔄", "label": "Skip to Work Session" }
    ]

    IpcHandler {
        target: "pomodoroMenu"
        function open() { root.open(); }
        function close() { root.close(); }
        function toggle() { root.toggle(); }
    }

    onActivated: (item) => Quickshell.execDetached(["pomodoro", item.key])
}
