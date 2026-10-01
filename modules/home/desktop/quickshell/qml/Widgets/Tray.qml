import QtQuick
import Quickshell.Services.SystemTray

// Deliberately its own file, importing nothing but SystemTray: importing
// Quickshell.Services.SystemTray in the same file as the qs.Services
// singletons (Status/Workspaces/Notifs/Apps) corrupts their construction —
// every property on them reads back as `undefined` — on quickshell 0.3.1.
// Isolating the import here avoids that entirely. Confirmed by hand against
// a series of minimal repros; worth re-checking against upstream on a
// quickshell version bump before ever merging this file into Bar.qml.
Row {
    id: root
    spacing: 6

    // The bar's PanelWindow, passed in rather than read from QsWindow so this
    // file keeps importing nothing beyond SystemTray (see above). Menus are
    // positioned relative to it.
    required property var window

    Repeater {
        model: SystemTray.items.values

        Item {
            id: trayItem
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22

            Image {
                anchors.fill: parent
                source: modelData.icon
                asynchronous: true
            }

            function showMenu() {
                const pos = trayItem.mapToItem(null, 0, trayItem.height);
                modelData.display(root.window, pos.x, pos.y);
            }

            // Left: activate, unless the item is nothing but a menu
            // (nm-applet), in which case open the menu instead.
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: modelData.onlyMenu ? trayItem.showMenu() : modelData.activate()
            }

            TapHandler {
                acceptedButtons: Qt.MiddleButton
                onTapped: modelData.secondaryActivate()
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: if (modelData.hasMenu) trayItem.showMenu()
            }
        }
    }
}
