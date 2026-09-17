import QtQuick
import qs.Common

// A pill that IS the control, not a display next to one: drag (or a plain
// tap) anywhere on it sets the value proportionally to where you pressed.
// At rest it's just icon + text, like every other pill; a lighter fill
// showing the level only fades in while actually pressed/dragging, as live
// feedback for where you're setting it to.
//
// Dragging shows `displayValue` moving instantly and only commits once, on
// release (`valueRequested` fires then, and on a plain tap) — not
// continuously during the drag. That split matters for brightness: unlike
// volume (an instant in-process Pipewire property write), each brightness
// change is a whole external process and, for a DDC/CI monitor, can take
// the better part of a second of real hardware round-trip (see scripts.
// nix's own comment on `brightness`) — no amount of debouncing the *calls*
// changes that a commit-per-pixel-of-drag was always going to feel behind.
// Previewing locally and committing once sidesteps the hardware latency
// instead of fighting it. Also sidesteps scroll: confirmed with a debug log
// that scroll events never reach any PanelWindow here at all, so dragging
// (the same press/move/release delivery clicking already proved works) is
// the only viable gesture for this anyway.
Rectangle {
    id: root

    property real value: 0 // 0-100, the authoritative value from outside
    property real sliderWidth: 108
    property bool hovering: false
    property color fillColor: Theme.accent
    // See the DragHandler below — true (volume's setting) commits on every
    // drag tick; false (brightness's) previews locally and commits once,
    // on release.
    property bool commitContinuously: true
    default property alias content: row.data

    // What the fill (and callers' own text, via this) should show right
    // now: the live drag position while interacting, the real value
    // otherwise. Bar.qml's percentage labels read this, not `value`
    // directly, so they track the drag as smoothly as the fill does.
    readonly property real displayValue: (leftTap.pressed || dragHandler.active) ? _previewValue : value
    property real _previewValue: value
    onValueChanged: if (!dragHandler.active && !leftTap.pressed) _previewValue = value

    // True from press to release, whether or not it ends up being a tap or
    // a drag — drives the fill's visibility.
    readonly property bool pressed: leftTap.pressed || dragHandler.active

    // Fires once per tap, and once on drag release — never continuously
    // during a drag. Callers that want a separate action on a bare click
    // (volume's mute toggle) use doubleTapped/rightTapped instead, which
    // don't set the value.
    signal valueRequested(real newValue)
    signal doubleTapped
    signal rightTapped

    width: sliderWidth
    height: Theme.barHeight - 10
    radius: height / 2
    color: hovering ? Theme.surfaceAlt : Theme.surface
    scale: hovering ? 1.06 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

    function valueAt(x) {
        return Math.max(0, Math.min(100, Math.round(x / root.width * 100)));
    }

    HoverHandler {
        onHoveredChanged: root.hovering = hovered
    }

    // The value fill — hidden at rest (the text alone conveys the value
    // when you're not actively setting it) and only faded in while pressed
    // or dragging, as the live feedback for where you're setting it to.
    //
    // It's a full-width pill revealed through a clipping window, not a
    // Rectangle whose own width shrinks: Qt clamps a Rectangle's radius to
    // half its width, so a shrinking one re-rounds its left cap into an
    // ever-tighter curve below ~2*radius — the fill visibly changes shape
    // as you drag through the low end. Clipping keeps the left cap at the
    // pill's own radius at every value and just cuts the fill off square on
    // the right, while still rounding the right edge as the fill nears full
    // width (that corner simply comes inside the window).
    Item {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(100, root.displayValue)) / 100
        clip: true
        opacity: root.pressed ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

        Rectangle {
            width: root.width
            height: parent.height
            radius: root.radius
            color: root.fillColor
        }
    }

    TapHandler {
        id: leftTap
        acceptedButtons: Qt.LeftButton
        onTapped: (eventPoint) => {
            const v = root.valueAt(eventPoint.position.x);
            root._previewValue = v;
            root.valueRequested(v);
        }
        onDoubleTapped: root.doubleTapped()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.rightTapped()
    }

    DragHandler {
        id: dragHandler
        target: null
        acceptedButtons: Qt.LeftButton
        onCentroidChanged: if (active) {
            root._previewValue = root.valueAt(centroid.position.x);
            // Volume is an instant in-process property write — committing
            // on every drag tick is what made it feel good, so it keeps
            // doing that. Only brightness (real hardware, real latency)
            // opts into preview-then-commit-on-release via this flag.
            if (root.commitContinuously)
                root.valueRequested(root._previewValue);
        }
        onActiveChanged: if (!active && !root.commitContinuously) root.valueRequested(root._previewValue)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }
}
