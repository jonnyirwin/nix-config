{ config, lib, ... }:

# Qt theming, rendered from the same palette as everything else.
#
# Qt has no equivalent of the desktop portal's colour-scheme signal: Qt 5 never
# learned to read it, and even on Qt 6 the portal only nudges the built-in
# light/dark switch — it cannot carry a scheme. So where GTK is told "prefer
# dark" and picks up the Catppuccin theme by name, Qt has to be handed the
# actual colours. qt5ct/qt6ct are the mechanism for that, and this module writes
# their palette from `jonny.theme.palette` so Qt follows a scheme switch with
# everything else instead of being pinned to one hand-written dark theme.
#
# Both are configured because the installed Qt apps straddle the versions:
# OpenSCAD and Flameshot are Qt 5, KiCad and Krita are Qt 6. The single
# QT_QPA_PLATFORMTHEME=qt5ct that Home Manager exports drives both — qt6ct's
# plugin advertises the `qt5ct` key as well as its own, so a Qt 6 app resolves
# it to qt6ct and reads the qt6ct config.

let
  cfg = config.jonny.desktop;
  palette = config.jonny.theme.palette;

  # qt5ct/qt6ct colour schemes are #AARRGGBB; the palette is #RRGGBB.
  argb = c: "#ff${lib.removePrefix "#" c}";

  # QPalette's roles, in the order qt5ct and qt6ct serialise them. Both write 21
  # comma-separated colours per state, ending at PlaceholderText. The list is
  # positional and unlabelled in the file, so the names are kept here.
  roles = {
    windowText = palette.fg;
    button = palette.surface;
    light = palette.surfaceActive;
    midlight = palette.surfaceAlt;
    dark = palette.bgInset;
    mid = palette.border;
    text = palette.fg;
    brightText = palette.fg;
    buttonText = palette.fg;

    # Base is the background of text entries and item views, Window the
    # background of the frame around them. Every palette here separates the two
    # (Catppuccin's base/mantle, Gruvbox's bg0/bg0_h), which is what makes a
    # focused text field readable against its dialog.
    base = palette.bgAlt;
    window = palette.bg;

    shadow = palette.bgInset;
    highlight = palette.accent;

    # Text drawn *on* the accent. `bg` is correct for both polarities by
    # construction: a dark scheme has a light accent and a dark bg, a light
    # scheme the reverse, so this always lands as the contrasting one.
    highlightedText = palette.bg;

    link = palette.info;
    linkVisited = palette.hues.purple;
    alternateBase = palette.surface;
    noRole = palette.bg; # unused by Qt, but the slot must be filled
    toolTipBase = palette.surfaceAlt;
    toolTipText = palette.fg;
    placeholderText = palette.fgMuted;
  };

  order = [
    "windowText"
    "button"
    "light"
    "midlight"
    "dark"
    "mid"
    "text"
    "brightText"
    "buttonText"
    "base"
    "window"
    "shadow"
    "highlight"
    "highlightedText"
    "link"
    "linkVisited"
    "alternateBase"
    "noRole"
    "toolTipBase"
    "toolTipText"
    "placeholderText"
  ];

  # Greyed-out widgets: only the ink changes, so the surfaces stay put and a
  # disabled control keeps its shape instead of dissolving into the window.
  dimmed = [ "windowText" "text" "brightText" "buttonText" "highlightedText" ];

  renderState = overrides:
    lib.concatMapStringsSep ", " (name: argb (overrides.${name} or roles.${name})) order;

  colorScheme = ''
    [ColorScheme]
    active_colors=${renderState { }}
    disabled_colors=${renderState (lib.genAttrs dimmed (_: palette.fgFaint))}
    inactive_colors=${renderState { }}
  '';

  schemePath = "${config.xdg.configHome}/qt5ct/colors/jonny.conf";

  # Fusion is the one style that both honours a custom palette and ships with
  # Qt itself. The platform styles either ignore custom_palette or drag in a
  # desktop environment we do not run.
  appearance = {
    Appearance = {
      style = "Fusion";
      custom_palette = true;
      color_scheme_path = schemePath;
      icon_theme = "Papirus-Dark";
      standard_dialogs = "default";
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    qt = {
      enable = true;

      # Installs qt5ct and qt6ct and exports QT_QPA_PLATFORMTHEME through
      # home.sessionVariables — which, unlike a fish shell hook, is in the
      # environment sway itself was started with, so apps launched from rofi or
      # a keybinding get it too.
      platformTheme.name = "qtct";

      qt5ctSettings = appearance;
      qt6ctSettings = appearance;
    };

    # One file, read by both: qt6ct is pointed at the qt5ct path above rather
    # than given a copy, so there is a single generated palette to reason about.
    xdg.configFile."qt5ct/colors/jonny.conf".text = colorScheme;
  };
}
