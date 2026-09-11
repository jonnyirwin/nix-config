import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

// Volume/brightness feedback that pops up over whatever you're doing and
// gets out of the way again — the thing waybar's pills can't do since
// they're pinned in the bar. One instance per screen would just show the
// same state twice, so this is a single overlay on the primary screen only.
PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "jonny-shell:osd"
    exclusionMode: PanelWindow.ExclusionMode.Ignore

    anchors.bottom: true
    implicitWidth: 260
    implicitHeight: 72
    color: "transparent"

    property string kind: "" // "volume" | "brightness"
    property real value: 0
    property bool muted: false

    // PanelWindow is a real window, not a QQuickItem — it has no `opacity`
    // of its own. `shown` drives the window's visible/margin; the fade lives
    // on the `fade` Item inside instead.
    property bool shown: false
    visible: shown
    margins.bottom: shown ? 48 : -implicitHeight
    Behavior on margins.bottom { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

    function show(newKind, newValue, newMuted) {
        kind = newKind;
        value = newValue;
        muted = !!newMuted;
        shown = true;
        hideTimer.restart();
    }

    Timer { id: hideTimer; interval: 1400; onTriggered: root.shown = false }

    Connections {
        target: Status
        function onVolumeChanged() { if (Status.volumeAvailable) root.show("volume", Status.volume, Status.muted); }
        function onMutedChanged() { if (Status.volumeAvailable) root.show("volume", Status.volume, Status.muted); }
        function onBrightnessPercentChanged() { if (Status.brightnessAvailable) root.show("brightness", Status.brightnessPercent, false); }
    }

    GlassPanel {
        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
        tint: root.kind === "volume" ? Theme.hues.blue : Theme.warning
        tintStrength: 0.4

        Column {
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 8

            Row {
                spacing: 10
                Text {
                    text: root.kind === "brightness" ? "󰃟" : (root.muted ? "󰸈" : (root.value > 60 ? "󰕾" : (root.value > 0 ? "󰖀" : "󰕿")))
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                }
                Text {
                    text: (root.kind === "volume" && root.muted) ? "Muted" : Math.round(root.value) + "%"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }
            }

            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: Theme.surface

                Rectangle {
                    height: parent.height
                    radius: 3
                    width: parent.width * Math.max(0, Math.min(100, root.muted ? 0 : root.value)) / 100
                    color: root.kind === "volume" ? Theme.hues.blue : Theme.warning
                    Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
