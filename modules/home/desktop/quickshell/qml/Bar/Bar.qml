import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

// Full-width, anchored flush to the top — an island cost real screen real
// estate for no real gain. The only decoration left is a soft bottom edge:
// flat top, gently rounded bottom corners, a hairline shadow under it.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData
    visible: Status.barVisible

    // Without -c jonny this targets the "default" config name and silently
    // finds no running instance to talk to — every ipc-calling click on
    // this bar went nowhere until this was added.
    function ipc(target, fn) {
        Quickshell.execDetached(["quickshell", "ipc", "-c", "jonny", "call", target, fn]);
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "jonny-shell:bar"

    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    // Without this, PanelWindow accepts no pointer input at all — clicks and
    // scroll silently do nothing while keyboard focus (a separate mechanism,
    // WlrKeyboardFocus above) works fine. Every PanelWindow in this shell
    // needs one; this cost a long debugging session to track down.
    mask: Region { item: island }

    Item {
        id: island
        anchors.fill: parent

        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.9)
        }

        MultiEffect {
            anchors.fill: backdrop
            source: backdrop
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.45)
            shadowBlur: 0.3
            shadowVerticalOffset: 2
            autoPaddingEnabled: true
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            // ---- Left: workspaces, as a single sliding highlight behind
            // fixed-size number slots rather than each pill resizing itself
            // — a tab-underline feel instead of a row of growing pills. ----
            Item {
                id: workspaceArea
                readonly property int slotSize: 28
                readonly property int slotGap: 4
                readonly property var wsList: Workspaces.forOutput(root.modelData ? root.modelData.name : "")
                readonly property int focusedIdx: wsList.findIndex(w => w.focused)

                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Math.max(slotSize, wsList.length * (slotSize + slotGap) - slotGap)
                implicitHeight: slotSize

                Rectangle {
                    id: slider
                    width: workspaceArea.slotSize
                    height: workspaceArea.slotSize
                    radius: width / 2
                    color: Theme.accent
                    visible: workspaceArea.focusedIdx >= 0
                    x: Math.max(0, workspaceArea.focusedIdx) * (workspaceArea.slotSize + workspaceArea.slotGap)
                    Behavior on x { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
                }

                Row {
                    spacing: workspaceArea.slotGap
                    Repeater {
                        model: workspaceArea.wsList
                        Item {
                            id: wsSlot
                            required property var modelData
                            width: workspaceArea.slotSize
                            height: workspaceArea.slotSize

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                border.width: wsSlot.modelData.urgent ? 2 : 0
                                border.color: Theme.error
                            }

                            Text {
                                anchors.centerIn: parent
                                text: String(wsSlot.modelData.name)
                                color: wsSlot.modelData.focused ? Theme.bgInset : (wsSlot.modelData.urgent ? Theme.error : Theme.fgMuted)
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }

                            TapHandler { onTapped: Workspaces.activate(wsSlot.modelData) }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // ---- Right: tray, status pills, clock ----
            //
            // RowLayout, not Row: Row top-aligns children regardless of
            // their own anchors (silently — no warning, unlike anchoring
            // left/right/fill inside a Row, which does warn). The pills
            // look fine either way since their content is centered inside
            // their own tall background rectangle, but Tray has no such
            // rectangle of its own, so it sat visibly nearer the top.
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Tray { Layout.alignment: Qt.AlignVCenter }

                SliderPill {
                    id: volumeSlider
                    visible: Status.volumeAvailable
                    value: Status.volume
                    fillColor: Theme.hues.blue
                    onValueRequested: (v) => Status.setVolume(v)
                    onDoubleTapped: Status.toggleMute()
                    onRightTapped: root.ipc("audioSwitcher", "toggle")

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Status.muted ? "󰸈" : (volumeSlider.displayValue > 60 ? "󰕾" : (volumeSlider.displayValue > 0 ? "󰖀" : "󰕿"))
                        color: Theme.hues.blue
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Status.muted ? "muted" : volumeSlider.displayValue + "%"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                    }
                }

                SliderPill {
                    id: brightnessSlider
                    visible: Status.brightnessAvailable
                    value: Status.brightnessPercent
                    fillColor: Theme.warning
                    commitContinuously: false
                    onValueRequested: (v) => Status.setBrightness(v)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰃟"
                        color: Theme.warning
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: brightnessSlider.displayValue + "%"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                    }
                }

                Pill {
                    visible: Status.hasBattery
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Status.batteryCharging ? "󰂄" : "󰁹"
                        color: Status.batteryState === "critical" ? Theme.error : (Status.batteryState === "warning" ? Theme.warning : Theme.success)
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (Status.batteryEstimated ? "~" : "") + Status.batteryPercent + "%"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                    }
                }

                Pill {
                    onClicked: root.ipc("networkMenu", "toggle")
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Status.networkIcon
                        color: Status.networkClass === "disconnected" ? Theme.fgMuted : Theme.hues.cyan
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                }

                Pill {
                    active: Status.idleInhibited
                    onClicked: Status.toggleIdleInhibitor()
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Status.idleInhibited ? "󰅶" : "󰒲"
                        color: Status.idleInhibited ? Theme.bgInset : Theme.fgMuted
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                }

                Pill {
                    id: clockPill
                    onClicked: root.ipc("controlCenter", "toggle")
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰥔"
                        color: Theme.info
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        id: clockText
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.info
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1

                        function refresh() { text = Qt.formatDateTime(new Date(), "HH:mm"); }
                        Component.onCompleted: refresh()
                        Timer { interval: 15000; running: true; repeat: true; onTriggered: clockText.refresh() }
                    }
                }
            }
        }

        // Independent of the RowLayout above — sibling, not child — and
        // anchored to the bar's true centre rather than sitting between two
        // equal-fillWidth spacers, which centres it only when the left and
        // right sections happen to be the same width. They aren't: the
        // right side (tray, pills, clock) is reliably wider than the
        // workspace indicator on the left, which is what pushed this
        // noticeably left of screen-centre before.
        CenterIsland {
            anchors.centerIn: parent
        }
    }
}
