pragma Singleton
import QtQuick

// Generated from jonny.theme.palette by modules/home/desktop/quickshell/default.nix.
// This placeholder is overwritten at build time — see the Nix module for the
// real template. Kept here so the QML tree is self-contained for local
// testing with `quickshell -p qml`.
QtObject {
    readonly property color bg: "#1e1e2e"
    readonly property color bgAlt: "#181825"
    readonly property color bgInset: "#11111b"
    readonly property color surface: "#313244"
    readonly property color surfaceAlt: "#45475a"
    readonly property color surfaceActive: "#585b70"
    readonly property color fg: "#cdd6f4"
    readonly property color fgMuted: "#a6adc8"
    readonly property color fgDim: "#bac2de"
    readonly property color fgSubtle: "#9399b2"
    readonly property color border: "#313244"
    readonly property color borderActive: "#b4befe"
    readonly property color highlight: "#f5e0dc"
    readonly property color accent: "#cba6f7"
    readonly property color error: "#f38ba8"
    readonly property color warning: "#f9e2af"
    readonly property color success: "#a6e3a1"
    readonly property color info: "#89b4fa"

    readonly property QtObject hues: QtObject {
        readonly property color red: "#f38ba8"
        readonly property color orange: "#fab387"
        readonly property color yellow: "#f9e2af"
        readonly property color green: "#a6e3a1"
        readonly property color cyan: "#94e2d5"
        readonly property color blue: "#89b4fa"
        readonly property color purple: "#cba6f7"
        readonly property color magenta: "#f5c2e7"
    }

    // Qt substitutes missing glyphs (the Nerd Font icons Dank Mono doesn't
    // have) from the system fontconfig fallback chain automatically — no
    // font.families list needed, and Text.font.family only takes one string
    // in this Qt build anyway.
    readonly property string fontFamily: "Dank Mono"
    readonly property int fontSize: 14

    // Geometry — the one shared vocabulary every module below borrows from,
    // so the bar, popups, toasts and OSD read as one shell rather than five.
    readonly property int radius: 20
    readonly property int radiusSmall: 12
    readonly property int barHeight: 40
    readonly property int gap: 8

    readonly property int animFast: 120
    readonly property int animMed: 220
    readonly property int animSlow: 400
    readonly property int animBounce: 550
}
