import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

// mako's replacement: a stack of glass toast cards, top-right, that push
// each other down as they arrive and animate out on dismiss or timeout.
PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "jonny-shell:notifications"
    exclusionMode: PanelWindow.ExclusionMode.Ignore

    anchors.top: true
    anchors.right: true
    implicitWidth: 340
    implicitHeight: column.height + 32
    color: "transparent"

    // See Bar.qml's comment — every PanelWindow needs this or it accepts no
    // pointer input at all (dismiss clicks would silently do nothing).
    mask: Region { item: column }

    IpcHandler {
        target: "notifications"

        function restoreLast(count: string) { Notifs.restoreLast(parseInt(count) || 1); }
        function dismissAll() { Notifs.dismissAll(); }
        function toggleDnd(): string {
            Notifs.doNotDisturb = !Notifs.doNotDisturb;
            return Notifs.doNotDisturb ? "Do not disturb: on" : "Do not disturb: off";
        }
    }

    Column {
        id: column
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 10

        Repeater {
            model: Notifs.toasts

            Item {
                id: card
                required property var model
                required property int index
                width: column.width
                height: cardBody.implicitHeight

                property bool dismissing: false
                opacity: dismissing ? 0 : 1
                scale: dismissing ? 0.92 : 1
                Behavior on opacity { NumberAnimation { duration: Theme.animMed } }
                Behavior on scale { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

                Component.onCompleted: entranceAnim.start()
                NumberAnimation {
                    id: entranceAnim
                    target: card
                    property: "x"
                    from: 60
                    to: 0
                    duration: Theme.animBounce
                    easing.type: Easing.OutBack
                }

                function dismiss() {
                    card.dismissing = true;
                    dismissTimer.start();
                }
                Timer { id: dismissTimer; interval: Theme.animMed; onTriggered: Notifs.dismiss(card.index) }

                Timer {
                    interval: card.model.timeoutMs
                    running: card.model.urgency !== "critical" && card.model.timeoutMs > 0
                    onTriggered: card.dismiss()
                }

                GlassPanel {
                    id: cardBody
                    anchors.left: parent.left
                    anchors.right: parent.right
                    tint: card.model.urgency === "critical" ? Theme.error : Theme.accent
                    tintStrength: card.model.urgency === "critical" ? 0.5 : 0.3

                    readonly property real implicitHeight: inner.implicitHeight + 24
                    height: implicitHeight

                    Column {
                        id: inner
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Row {
                            width: parent.width
                            spacing: 8
                            Rectangle {
                                width: 4; height: 16; radius: 2
                                color: card.model.urgency === "critical" ? Theme.error : Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: card.model.appName
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                            Item { width: parent.width - 200; height: 1 }
                            Text {
                                text: "✕"
                                color: Theme.fgMuted
                                font.pixelSize: 12
                                TapHandler { onTapped: card.dismiss() }
                            }
                        }
                        Text {
                            width: parent.width
                            text: card.model.summary
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            width: parent.width
                            visible: card.model.body !== ""
                            text: card.model.body
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: card.dismiss()
                    }
                }
            }
        }
    }
}
