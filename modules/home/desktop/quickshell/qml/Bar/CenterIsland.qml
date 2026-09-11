import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services

// The one thing meant to make this bar feel like more than a recoloured
// waybar: a single capsule that stays collapsed to nothing when there is
// nothing to say, and morphs open for whichever of media or pomodoro is
// live — real album art and transport controls off Mpris, not a text
// scroller. Media wins over pomodoro when both are running.
Item {
    id: root

    readonly property bool showMedia: Status.mediaAvailable
    readonly property bool showPomodoro: !showMedia && Status.pomodoroEnabled && Status.pomodoroText !== ""
    readonly property bool expanded: showMedia || showPomodoro
    readonly property real targetWidth: expanded ? (showMedia ? 260 : 150) : 0

    property real animW: targetWidth
    onTargetWidthChanged: animW = targetWidth
    Behavior on animW { NumberAnimation { duration: Theme.animBounce; easing.type: Easing.OutBack } }

    width: animW
    height: Theme.barHeight - 10
    clip: true
    visible: animW > 1

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface
    }

    // ---- Media ----
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 12
        visible: root.showMedia
        opacity: root.showMedia ? 1 : 0
        spacing: 8
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

        Rectangle {
            Layout.preferredWidth: parent.height - 8
            Layout.preferredHeight: parent.height - 8
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: Theme.surfaceActive
            clip: true

            Image {
                anchors.fill: parent
                source: Status.mediaArtUrl
                visible: Status.mediaArtUrl !== ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Text {
                anchors.centerIn: parent
                visible: Status.mediaArtUrl === ""
                text: "󰝚"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 130
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: Status.mediaTitle || "—"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: Status.mediaArtist
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 4
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4
            Text {
                text: "󰒮"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                TapHandler { onTapped: Status.mediaPrevious() }
            }
            Text {
                text: Status.mediaPlaying ? "󰏤" : "󰐊"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                TapHandler { onTapped: Status.mediaTogglePlaying() }
            }
            Text {
                text: "󰒭"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                TapHandler { onTapped: Status.mediaNext() }
            }
        }
    }

    // ---- Pomodoro ----
    Row {
        anchors.centerIn: parent
        visible: root.showPomodoro
        opacity: root.showPomodoro ? 1 : 0
        spacing: 8
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

        Text {
            text: Status.pomodoroClass === "break" ? "󰅶" : "󰄉"
            color: Status.pomodoroClass === "break" ? Theme.hues.orange : Theme.success
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        Text {
            // pomodoro.sh's own text already leads with an icon
            // ("󰄉 12:34 ████░░░░ 45%") — strip it so there's only the one
            // icon, ours, which also tells break from focus by colour.
            text: Status.pomodoroText.replace(/^\S+\s+/, "")
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
        }
    }

    TapHandler {
        enabled: root.showPomodoro
        // -c jonny: see Bar.qml's ipc() comment — bare "ipc call" with no
        // -c/-i targets a "default" config that doesn't exist here.
        onTapped: Quickshell.execDetached(["quickshell", "ipc", "-c", "jonny", "call", "pomodoroMenu", "toggle"])
    }
}
