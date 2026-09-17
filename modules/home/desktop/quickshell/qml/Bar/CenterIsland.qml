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

    // pomodoro.sh's own text carries an icon, a "MM:SS" remaining-time, an
    // ASCII progress bar and a trailing percentage all in one string (e.g.
    // "󰄉 12:34 ████░░░░ 45%") — built for a waybar tooltip, not this pill.
    // Pull just the time out for the centred label and the percentage out
    // to drive the fill below, same idea as SliderPill's displayValue but
    // sourced from text instead of a number. IDLE's "Start" text matches
    // neither pattern, so both fall back sanely (full text, 0% fill).
    readonly property string _pomodoroStripped: Status.pomodoroText.replace(/^\S+\s+/, "")
    readonly property var _pomodoroTimeMatch: root._pomodoroStripped.match(/^(\d{1,2}:\d{2})/)
    readonly property var _pomodoroPctMatch: root._pomodoroStripped.match(/(\d+)%\s*$/)
    readonly property string pomodoroDisplayText: root._pomodoroTimeMatch ? root._pomodoroTimeMatch[1] : root._pomodoroStripped
    readonly property real pomodoroProgress: root._pomodoroPctMatch ? parseInt(root._pomodoroPctMatch[1]) : 0

    property real animW: targetWidth
    onTargetWidthChanged: animW = targetWidth
    Behavior on animW { NumberAnimation { duration: Theme.animBounce; easing.type: Easing.OutBack } }

    width: animW
    height: Theme.barHeight - 10
    clip: true
    visible: animW > 1

    Rectangle {
        id: background
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
    //
    // Same visual language as SliderPill (volume/brightness): a fill that
    // shows how far through the bar you are, with the label centred on top.
    // Unlike those, this fill is a passive readout, not a control — there's
    // nothing to drag or click-to-set, so it just stays visible rather than
    // fading in only while pressed.
    //
    // Tried masking a flat-edged fill against `background` via
    // `layer.effect: MultiEffect { maskEnabled: true; maskSource: ... }` to
    // clip it exactly to the pill's silhouette — rendered nothing at all in
    // this Quickshell/Qt build (no QML error, just an invisible layer), so
    // it takes SliderPill's approach instead: a full-width rounded fill
    // revealed through a clipping window, which keeps the left cap at the
    // pill's own radius however little progress there is (a Rectangle that
    // shrinks below 2*radius has its radius clamped by Qt and changes shape
    // as it goes) and cuts the leading edge off square.
    Item {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: root.showPomodoro
        width: parent.width * Math.max(0, Math.min(100, root.pomodoroProgress)) / 100
        clip: true
        opacity: root.showPomodoro ? 0.45 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on width { NumberAnimation { duration: Theme.animFast } }

        Rectangle {
            width: root.width
            height: parent.height
            radius: height / 2
            color: Status.pomodoroClass === "break" ? Theme.hues.orange : Theme.success
        }
    }

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
            text: root.pomodoroDisplayText
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
