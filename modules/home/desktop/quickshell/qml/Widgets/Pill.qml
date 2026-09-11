import QtQuick
import qs.Common

// A bar capsule. Shares the same shape language as GlassPanel's corners so
// the bar and its popouts read as one system, but stays a plain flat
// Rectangle — a row of a dozen of these blurring individually would be
// wasteful, and the bar already sits on the glass of Bar.qml's own backdrop.
//
// Click/hover handlers live on this root Rectangle rather than inside
// `content` deliberately: `content` aliases into a Row, whose own bounds are
// only as big as its children — a handler placed there (as a child of the
// caller's declaration) only ever covers a tight box around the icon/text,
// not the padded pill around it, so clicks near the edge silently missed.
//
// No WheelHandler here (there was one) — scroll events never reach any of
// this shell's PanelWindows here at all, confirmed with a debug log that
// never fired on a real scroll. Volume/brightness use SliderPill (drag)
// instead of scroll-to-adjust for that reason.
Rectangle {
    id: root

    property bool active: false
    property bool hovering: false
    default property alias content: row.data

    signal clicked
    signal rightClicked

    implicitWidth: row.implicitWidth + 24
    implicitHeight: Theme.barHeight - 10
    radius: height / 2
    color: active ? Theme.accent : (hovering ? Theme.surfaceAlt : Theme.surface)
    scale: hovering ? 1.06 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

    HoverHandler {
        onHoveredChanged: root.hovering = hovered
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.clicked()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.rightClicked()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }
}
