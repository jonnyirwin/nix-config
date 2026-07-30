# Nord.
#
# Declared in Nord's own vocabulary (nord0..nord15, grouped as Polar Night,
# Snow Storm, Frost and Aurora) and mapped onto roles. Nord's palette is
# smaller than Catppuccin's, but every role has a genuine Nord colour — the
# Frost group covers the cool hues and Aurora the warm ones.
#
# Source: https://www.nordtheme.com/docs/colors-and-palette

let
  raw = {
    # Polar Night
    nord0 = "#2e3440";
    nord1 = "#3b4252";
    nord2 = "#434c5e";
    nord3 = "#4c566a";

    # Snow Storm
    nord4 = "#d8dee9";
    nord5 = "#e5e9f0";
    nord6 = "#eceff4";

    # Frost
    nord7 = "#8fbcbb";
    nord8 = "#88c0d0";
    nord9 = "#81a1c1";
    nord10 = "#5e81ac";

    # Aurora
    nord11 = "#bf616a"; # red
    nord12 = "#d08770"; # orange
    nord13 = "#ebcb8b"; # yellow
    nord14 = "#a3be8c"; # green
    nord15 = "#b48ead"; # purple
  };
in
{
  inherit raw;

  polarity = "dark";

  # ---- Structure ----
  bg = raw.nord0;
  bgAlt = "#292e39"; # between nord0 and a darker inset
  bgInset = "#242933";

  surface = raw.nord1;
  surfaceAlt = raw.nord2;
  surfaceActive = raw.nord3;

  # ---- Foreground ramp ----
  fg = raw.nord4;
  fgDim = "#c8cedb";
  fgSubtle = "#b8c0cf";
  fgMuted = "#7b88a1";
  fgFaint = "#616e88";

  # ---- Lines and emphasis ----
  border = raw.nord3;
  borderActive = raw.nord8; # Frost blue is Nord's focus colour
  highlight = raw.nord6;

  # ---- Status ----
  error = raw.nord11;
  warning = raw.nord13;
  success = raw.nord14;
  info = raw.nord8;

  # ---- Distinct hues ----
  hues = {
    red = raw.nord11;
    orange = raw.nord12;
    yellow = raw.nord13;
    green = raw.nord14;
    cyan = raw.nord7;
    blue = raw.nord9;
    purple = raw.nord15;
    magenta = raw.nord15;
  };

  ansi = {
    black = raw.nord1;
    red = raw.nord11;
    green = raw.nord14;
    yellow = raw.nord13;
    blue = raw.nord9;
    magenta = raw.nord15;
    cyan = raw.nord8;
    white = raw.nord5;

    brightBlack = raw.nord3;
    brightRed = raw.nord11;
    brightGreen = raw.nord14;
    brightYellow = raw.nord13;
    brightBlue = raw.nord10;
    brightMagenta = raw.nord15;
    brightCyan = raw.nord7;
    brightWhite = raw.nord6;
  };
}
