import QtQuick
import Quickshell
import Quickshell.Io
import qs.Widgets

// Replaces scripts.nix's power-menu (a static rofi -dmenu list). The
// control-centre's power row (ControlCenter.qml) covers the same ground for
// a mouse in a hurry; this is the same options for the dedicated keybinding.
PickerWindow {
    id: root

    namespaceSuffix: "power-menu"
    title: "Power Menu"
    searchEnabled: false
    panelWidth: 320
    panelHeight: 280

    items: [
        { "key": "lock", "icon": "󰐥", "label": "Lock" },
        { "key": "logout", "icon": "󰍃", "label": "Logout" },
        { "key": "suspend", "icon": "󰤄", "label": "Suspend" },
        { "key": "reboot", "icon": "󰜉", "label": "Reboot" },
        { "key": "shutdown", "icon": "⏻", "label": "Shutdown" }
    ]

    IpcHandler {
        target: "powerMenu"
        function open() { root.open(); }
        function close() { root.close(); }
        function toggle() { root.toggle(); }
    }

    onActivated: (item) => {
        switch (item.key) {
        case "lock": Quickshell.execDetached(["lock-screen"]); break;
        case "logout": Quickshell.execDetached(["swaymsg", "exit"]); break;
        case "suspend": Quickshell.execDetached(["systemctl", "suspend"]); break;
        case "reboot": Quickshell.execDetached(["systemctl", "reboot"]); break;
        case "shutdown": Quickshell.execDetached(["systemctl", "poweroff"]); break;
        }
    }
}
