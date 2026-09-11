import QtQuick
import QtQuick.Effects
import qs.Common

// The one surface every popup (control centre, launcher, toasts, OSD, session
// menu) is built on: a frosted, elevated card rather than waybar/mako/rofi's
// flat pills. `tint` lets a caller lean the glass toward the accent (the
// launcher) or an urgency colour (a critical toast) without redrawing it.
Item {
    id: root

    property color tint: Theme.surface
    property real tintStrength: 0.55
    property real cornerRadius: Theme.radius
    default property alias content: body.data

    readonly property color _base: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.72)

    Rectangle {
        id: shadowSource
        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.tint(root._base, Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.tintStrength * 0.35))
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)
    }

    MultiEffect {
        anchors.fill: shadowSource
        source: shadowSource
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.55)
        shadowBlur: 0.7
        shadowVerticalOffset: 10
        shadowHorizontalOffset: 0
        autoPaddingEnabled: true
    }

    Item {
        id: body
        anchors.fill: parent
    }
}
