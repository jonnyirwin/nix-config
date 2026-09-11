import QtQuick
import Quickshell
import Quickshell.Io
import qs.Bar
import qs.OSD
import qs.Notifications
import qs.ControlCenter
import qs.Launcher
import qs.Pickers
import qs.Services

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    OSD {}
    NotificationPopups {}
    ControlCenter {}
    Launcher {}
    WindowSwitcher {}
    NetworkMenu {}
    AudioSwitcher {}
    ClipboardHistory {}
    ScreenRotate {}
    PowerMenu {}
    CommandMenu {}
    PomodoroMenu {}

    // Bound to jonny.desktop.keys.toggleBar in sway.nix.
    IpcHandler {
        target: "bar"
        function toggle() { Status.toggleBar(); }
    }
}
