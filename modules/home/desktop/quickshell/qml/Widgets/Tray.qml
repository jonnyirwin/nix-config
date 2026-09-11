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

    Repeater {
        model: SystemTray.items.values

        Item {
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22

            Image {
                anchors.fill: parent
                source: modelData.icon
                asynchronous: true
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: modelData.activate()
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: if (modelData.hasMenu) modelData.secondaryActivate()
            }
        }
    }
}
