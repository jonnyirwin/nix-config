import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

// Replaces command-menu.nix's rofi hub: the "everything nested" menu,
// Omarchy's one idea worth copying wholesale. Same shape (categories that
// open submenus, Escape goes up one level rather than closing outright) —
// just native QML instead of a bash script driving repeated rofi -dmenu
// calls, so it can actually look like the rest of this shell instead of
// looking like rofi.
//
// Doesn't carry the bash version's dimmed-keybinding hint column — that
// read jonny.desktop.keys directly in a way this file can't without a
// generated data file of its own. Worth adding if this earns its keep.
PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "jonny-shell:command-menu"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    property bool shown: false
    visible: shown

    function ipc(target, fn) {
        Quickshell.execDetached(["quickshell", "ipc", "-c", "jonny", "call", target, fn]);
    }

    // Each entry: { label, icon?, action } for a leaf, or
    // { label, icon?, children } for a submenu. `repeat: true` keeps the
    // menu open after the action runs (brightness step, wallpaper step).
    readonly property var rootMenu: [
        { "label": "Apps", "icon": "󰍉", "action": () => root.ipc("launcher", "toggle") },
        { "label": "Windows", "icon": "󰖯", "action": () => root.ipc("windowSwitcher", "toggle") },
        { "label": "Clipboard", "icon": "󰅍", "action": () => root.ipc("clipboardHistory", "toggle") },
        { "label": "Network", "icon": "󰤨", "action": () => root.ipc("networkMenu", "toggle") },
        {
            "label": "Capture", "icon": "󰄀", "children": [
                { "label": "Screenshot to clipboard", "action": () => Quickshell.execDetached(["screenshot-region"]) },
                { "label": "Screenshot and annotate", "action": () => Quickshell.execDetached(["screenshot-annotate"]) },
                { "label": "Toggle screen recording", "action": () => Quickshell.execDetached(["record-toggle"]) },
                { "label": "OCR region", "action": () => Quickshell.execDetached(["ocr-region"]) },
                { "label": "Scan QR code", "action": () => Quickshell.execDetached(["qr-decode"]) },
                { "label": "Pick colour", "action": () => Quickshell.execDetached(["color-picker"]) },
                { "label": "Emoji", "action": () => Quickshell.execDetached(["emoji-picker"]) }
            ]
        },
        {
            "label": "Audio", "icon": "󰕾", "children": [
                { "label": "Output device", "action": () => root.ipc("audioSwitcher", "toggle") }
            ]
        },
        {
            "label": "Display", "icon": "󰍹", "children": [
                { "label": "Arrange outputs", "action": () => Quickshell.execDetached(["wdisplays"]) },
                { "label": "Rotate output", "action": () => root.ipc("screenRotate", "toggle") },
                { "label": "Brightness up", "repeat": true, "action": () => Status.brightnessUp() },
                { "label": "Brightness down", "repeat": true, "action": () => Status.brightnessDown() }
            ]
        },
        {
            "label": "Notifications", "icon": "󰂚", "children": [
                { "label": "Replay last", "action": () => Notifs.restoreLast(1) },
                { "label": "Replay last ten", "action": () => Notifs.restoreLast(10) }
            ]
        },
        {
            "label": "Wallpaper", "icon": "󰸉", "children": [
                { "label": "Next", "repeat": true, "action": () => Quickshell.execDetached(["wallpaper", "next"]) },
                { "label": "Previous", "repeat": true, "action": () => Quickshell.execDetached(["wallpaper", "prev"]) },
                { "label": "Fetch today's pictures", "action": () => Quickshell.execDetached(["wallpaper", "next"]) }
            ]
        },
        {
            "label": "Power", "icon": "⏻", "children": [
                { "label": "Power menu", "action": () => root.ipc("powerMenu", "toggle") },
                { "label": "Lock screen", "action": () => Quickshell.execDetached(["lock-screen"]) },
                { "label": "Idle inhibitor", "action": () => Status.toggleIdleInhibitor() }
            ]
        }
    ]

    property var stack: []
    readonly property var currentFrame: stack.length > 0 ? stack[stack.length - 1] : null
    readonly property var currentItems: currentFrame ? currentFrame.items : rootMenu
    readonly property string currentTitle: currentFrame ? currentFrame.title : "Command"

    property int selectedIndex: 0

    function open() {
        stack = [];
        selectedIndex = 0;
        shown = true;
    }

    function close() {
        shown = false;
    }

    function toggle() {
        if (shown)
            close();
        else
            open();
    }

    function back() {
        if (stack.length > 0) {
            stack = stack.slice(0, -1);
            selectedIndex = 0;
        } else {
            close();
        }
    }

    function activate(item) {
        if (!item)
            return;
        if (item.children) {
            stack = stack.concat([{ "title": item.label, "items": item.children }]);
            selectedIndex = 0;
            return;
        }
        item.action();
        if (!item.repeat)
            close();
    }

    // See Bar.qml's comment — every PanelWindow needs this or it accepts no
    // pointer input at all. Masked to the scrim since that spans the whole
    // window (needed for click-outside-to-close).
    mask: Region { item: scrim }

    IpcHandler {
        target: "commandMenu"
        function open() { root.open(); }
        function close() { root.close(); }
        function toggle() { root.toggle(); }
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        TapHandler { onTapped: root.close() }
    }

    GlassPanel {
        id: panel
        anchors.centerIn: parent
        width: 420
        height: Math.min(540, 100 + root.currentItems.length * 44)
        tint: Theme.accent
        tintStrength: 0.3
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 24

            TapHandler {
                enabled: root.stack.length > 0
                onTapped: root.back()
            }

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                visible: root.stack.length > 0
                Text { text: "󰁮"; color: Theme.fgMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
                Text { text: "Back"; color: Theme.fgMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1 }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentTitle
                color: Theme.fg
                font.family: Theme.fontFamily
                font.bold: true
                font.pixelSize: Theme.fontSize + 1
            }
        }

        ListView {
            id: list
            anchors.top: header.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            clip: true
            model: root.currentItems
            currentIndex: root.selectedIndex
            highlightMoveDuration: Theme.animFast

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: 44
                radius: Theme.radiusSmall
                color: index === root.selectedIndex ? Theme.accent : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!row.modelData.icon
                        text: row.modelData.icon || ""
                        color: index === root.selectedIndex ? Theme.bgInset : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label
                        color: index === root.selectedIndex ? Theme.bgInset : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!row.modelData.children
                        text: "›"
                        color: index === root.selectedIndex ? Theme.bgInset : Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                TapHandler {
                    onTapped: root.activate(row.modelData)
                }
            }
        }
    }

    Item {
        focus: root.shown
        Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, root.currentItems.length - 1)
        Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
        Keys.onEscapePressed: root.back()
        Keys.onReturnPressed: root.activate(root.currentItems[root.selectedIndex])
        Keys.onEnterPressed: root.activate(root.currentItems[root.selectedIndex])
    }
}
