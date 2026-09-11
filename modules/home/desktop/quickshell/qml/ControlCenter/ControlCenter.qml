import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

// The quick-settings panel waybar has no equivalent for: toggles, sliders
// and a calendar-free clock detail, opened from the bar's clock pill.
PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "jonny-shell:control-center"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Full-screen, like Launcher/PickerWindow — not just a 340x420 window
    // pinned top-right — so there's a scrim to click outside onto. The
    // small top-right box was its own window before, which meant there was
    // no "outside" on its own surface to catch a dismiss click; the only
    // way out was toggling the clock pill again.
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    property bool shown: false
    visible: shown

    function close() { root.shown = false; }

    // See Bar.qml's comment — every PanelWindow needs this or it accepts no
    // pointer input at all (every toggle/slider here would silently do
    // nothing). Masked to the scrim since that spans the whole window.
    mask: Region { item: scrim }

    IpcHandler {
        target: "controlCenter"
        function toggle() { root.shown = !root.shown; }
        function open() { root.shown = true; }
        function close() { root.close(); }
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        TapHandler { onTapped: root.close() }

        Keys.onEscapePressed: root.close()
        focus: root.shown
    }

    GlassPanel {
        id: glass
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 12
        width: 340
        height: 420
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.94
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
        tint: Theme.accent
        tintStrength: 0.25

        Column {
            id: settingsColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 18
            spacing: 14

            Row {
                width: parent.width
                Text {
                    text: "Control Centre"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: true
                }
            }

            // ---- Toggle grid ----
            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: [
                        { label: "Do Not Disturb", icon: "󰂛", active: Notifs.doNotDisturb, toggle: () => Notifs.doNotDisturb = !Notifs.doNotDisturb },
                        { label: "Stay Awake", icon: "󰒲", active: Status.idleInhibited, toggle: () => Status.toggleIdleInhibitor() }
                    ]

                    Rectangle {
                        required property var modelData
                        width: (parent.width - 8) / 2
                        height: 56
                        radius: Theme.radiusSmall
                        color: modelData.active ? Theme.accent : Theme.surface

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                color: modelData.active ? Theme.bgInset : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: modelData.active ? Theme.bgInset : Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }

                        TapHandler { onTapped: modelData.toggle() }
                    }
                }
            }

            // ---- Sliders ----
            Column {
                width: parent.width
                spacing: 10
                visible: Status.volumeAvailable

                Row {
                    width: parent.width
                    spacing: 8
                    Text { text: "󰕾"; color: Theme.hues.blue; font.family: Theme.fontFamily; font.pixelSize: 16 }
                    Text { text: "Volume · " + Status.volume + "%"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1 }
                }
                Rectangle {
                    id: volTrack
                    width: parent.width
                    height: 10
                    radius: 5
                    color: Theme.surface
                    Rectangle {
                        height: parent.height
                        radius: 5
                        width: parent.width * Status.volume / 100
                        color: Theme.hues.blue
                    }
                    TapHandler {
                        onTapped: (eventPoint) => Status.setVolume(Math.round(eventPoint.position.x / volTrack.width * 100))
                    }
                    DragHandler {
                        target: null
                        onActiveChanged: if (active) {} // drag handled via centroid below
                        onCentroidChanged: if (active) Status.setVolume(Math.round(centroid.position.x / volTrack.width * 100))
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 10
                visible: Status.brightnessAvailable

                Row {
                    width: parent.width
                    spacing: 8
                    Text { text: "󰃟"; color: Theme.warning; font.family: Theme.fontFamily; font.pixelSize: 16 }
                    Text { text: "Brightness · " + Status.brightnessPercent + "%"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1 }
                }
                Row {
                    width: parent.width
                    spacing: 10
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: Theme.surface
                        Text { anchors.centerIn: parent; text: "−"; color: Theme.fg; font.pixelSize: 16 }
                        TapHandler { onTapped: Status.brightnessDown() }
                    }
                    Rectangle {
                        width: parent.width - 84
                        height: 10
                        radius: 5
                        color: Theme.surface
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            height: parent.height
                            radius: 5
                            width: parent.width * Status.brightnessPercent / 100
                            color: Theme.warning
                        }
                    }
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: Theme.surface
                        Text { anchors.centerIn: parent; text: "+"; color: Theme.fg; font.pixelSize: 16 }
                        TapHandler { onTapped: Status.brightnessUp() }
                    }
                }
            }

        }

        // ---- Power row — pinned to the panel's bottom edge, not the
        // Column above (a Column child can't use bottom/top anchors). ----
        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 18
            spacing: 10

            Repeater {
                model: [
                    { icon: "󰐥", command: ["lock-screen"] },
                    { icon: "󰍃", command: ["swaymsg", "exit"] },
                    { icon: "󰤄", command: ["systemctl", "suspend"] },
                    { icon: "󰜉", command: ["systemctl", "reboot"] },
                    { icon: "⏻", command: ["systemctl", "poweroff"] }
                ]
                Rectangle {
                    required property var modelData
                    width: 48; height: 40
                    radius: Theme.radiusSmall
                    color: Theme.surface
                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        color: modelData.icon === "⏻" ? Theme.error : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }
                    TapHandler {
                        onTapped: {
                            Quickshell.execDetached(modelData.command);
                            root.shown = false;
                        }
                    }
                }
            }
        }
    }
}
