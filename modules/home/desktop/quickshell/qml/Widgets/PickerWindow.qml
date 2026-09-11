import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets

// Generic replacement for `rofi -dmenu`: a searchable list overlay. Unlike
// rofi -dmenu, this can't just "print the chosen line back to the calling
// script" — quickshell's IPC is async, not a blocking subprocess — so each
// user of this component owns its own action (see onActivated) rather than
// a caller switching on stdout. That is the one real shape difference from
// the rofi version; everything else (search, keyboard nav, Escape to
// cancel) works the same.
PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "jonny-shell:picker:" + root.namespaceSuffix
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    property string namespaceSuffix: "picker"
    property string title: ""
    property string placeholder: "Search…"
    property bool searchEnabled: true
    property real panelWidth: 480
    property real panelHeight: 420

    // [{ label, sublabel?, icon?, key? }, ...] — `key` is whatever onActivated
    // needs to act; label/sublabel/icon are display-only.
    property var items: []

    property bool shown: false
    visible: shown

    signal activated(var item)
    signal aboutToOpen

    function open() {
        shown = true;
        filterText = "";
        selectedIndex = 0;
        aboutToOpen();
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function close() {
        shown = false;
    }

    function toggle() {
        if (shown)
            close();
        else
            open();
    }

    property string filterText: ""
    property int selectedIndex: 0

    readonly property var filtered: {
        const q = filterText.toLowerCase().trim();
        if (q === "")
            return items;
        return items.filter(it => (it.label + " " + (it.sublabel || "")).toLowerCase().includes(q));
    }

    // See Bar.qml's comment — every PanelWindow needs this or it accepts no
    // pointer input at all. Masked to the scrim since that spans the whole
    // window (needed for click-outside-to-close).
    mask: Region { item: scrim }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        TapHandler { onTapped: root.close() }
    }

    GlassPanel {
        id: panel
        anchors.centerIn: parent
        width: root.panelWidth
        height: root.panelHeight
        tint: Theme.accent
        tintStrength: 0.3
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        Text {
            id: titleText
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            visible: root.title !== ""
            text: root.title
            color: Theme.fg
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: Theme.fontSize + 1
        }

        Rectangle {
            id: searchBox
            anchors.top: titleText.visible ? titleText.bottom : parent.top
            anchors.topMargin: titleText.visible ? 10 : 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 38
            radius: 999
            color: Theme.surface
            visible: root.searchEnabled

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                clip: true

                Text {
                    // TextInput's own text is AlignVCenter within its full
                    // 38px-tall box (anchors.fill: parent above), but a
                    // plain child Text defaults to the top of that box —
                    // without this it sat visibly higher than real typed
                    // text would.
                    anchors.verticalCenter: parent.verticalCenter
                    visible: parent.text === ""
                    text: root.placeholder
                    color: Theme.fgSubtle
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                onTextChanged: {
                    root.filterText = text;
                    root.selectedIndex = 0;
                }

                Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, root.filtered.length - 1)
                Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                Keys.onEscapePressed: root.close()
                Keys.onReturnPressed: {
                    if (root.filtered.length > 0) {
                        root.activated(root.filtered[root.selectedIndex]);
                        root.close();
                    }
                }
            }
        }

        ListView {
            id: list
            anchors.top: root.searchEnabled ? searchBox.bottom : (titleText.visible ? titleText.bottom : parent.top)
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            clip: true
            model: root.filtered
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

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Row {
                        spacing: 8
                        Text {
                            visible: !!row.modelData.icon
                            text: row.modelData.icon || ""
                            color: index === root.selectedIndex ? Theme.bgInset : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                        Text {
                            text: row.modelData.label
                            color: index === root.selectedIndex ? Theme.bgInset : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                    }
                    Text {
                        visible: !!row.modelData.sublabel
                        text: row.modelData.sublabel || ""
                        color: index === root.selectedIndex ? Theme.bgInset : Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 3
                    }
                }

                TapHandler {
                    onTapped: {
                        root.activated(row.modelData);
                        root.close();
                    }
                }
            }
        }
    }
}
