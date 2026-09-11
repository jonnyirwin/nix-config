import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

// rofi -show drun's replacement: a centred search-and-grid overlay instead
// of a dropdown list, in the same glass language as everything else here.
PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "jonny-shell:launcher"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    // PanelWindow is a window, not a QQuickItem — no opacity of its own.
    // `shown` drives the window's visible; the fade lives on `fade` below.
    property bool shown: false
    visible: shown

    property var results: []

    function open() {
        shown = true;
        query.text = "";
        Apps.refresh();
        results = Apps.entries;
        Qt.callLater(() => query.forceActiveFocus());
    }

    function close() {
        shown = false;
        selectedIndex = 0;
    }

    function toggle() {
        if (shown) close(); else open();
    }

    property int selectedIndex: 0

    // See Bar.qml's comment — every PanelWindow needs this or it accepts no
    // pointer input at all. Masked to the scrim since that spans the whole
    // window (needed for click-outside-to-close).
    mask: Region { item: scrim }

    IpcHandler {
        target: "launcher"
        function open() { root.open(); }
        function close() { root.close(); }
        function toggle() { root.toggle(); }
    }

    // Scrim
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        TapHandler { onTapped: root.close() }
    }

    GlassPanel {
        id: panel
        anchors.centerIn: parent
        width: 560
        height: 420
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        tint: Theme.accent
        tintStrength: 0.3

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Rectangle {
                width: parent.width
                height: 44
                radius: 999
                color: Theme.surface

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }

                    TextInput {
                        id: query
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 40
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        clip: true
                        focus: true

                        Text {
                            visible: query.text === ""
                            text: "Search apps…"
                            color: Theme.fgSubtle
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 1
                        }

                        onTextChanged: {
                            root.results = Apps.search(query.text);
                            root.selectedIndex = 0;
                        }

                        Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, root.results.length - 1)
                        Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                        Keys.onEscapePressed: root.close()
                        Keys.onReturnPressed: {
                            if (root.results.length > 0) {
                                Apps.launch(root.results[root.selectedIndex]);
                                root.close();
                            }
                        }
                    }
                }
            }

            ListView {
                id: list
                width: parent.width
                height: parent.height - 56
                clip: true
                model: root.results
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
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Rectangle {
                            width: 28; height: 28; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: row.modelData.icon === "" ? Theme.surfaceActive : "transparent"
                            visible: row.modelData.icon === ""
                            Text {
                                anchors.centerIn: parent
                                text: row.modelData.name.charAt(0).toUpperCase()
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }
                        }
                        Image {
                            width: 28; height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            source: row.modelData.icon
                            visible: row.modelData.icon !== ""
                            asynchronous: true
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.name
                            color: index === root.selectedIndex ? Theme.bgInset : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    TapHandler {
                        onTapped: {
                            Apps.launch(row.modelData);
                            root.close();
                        }
                    }
                }
            }
        }
    }
}
