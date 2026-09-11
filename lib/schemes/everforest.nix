# Everforest (dark, medium contrast — the theme's default background).
#
# Declared in the theme's own vocabulary (bg0..bg5, the grey ramp used for
# comments, and the named accent colours) and mapped onto roles.
#
# Source: https://github.com/sainnhe/everforest

let
  raw = {
    bgDim = "#232a2e";
    bg0 = "#2d353b";
    bg1 = "#343f44";
    bg2 = "#3d484d";
    bg3 = "#475258";
    bg4 = "#4f585e";
    bg5 = "#56635f";

    fg = "#d3c6aa";
    grey0 = "#7a8478";
    grey1 = "#859289";
    grey2 = "#9da9a0";

    red = "#e67e80";
    orange = "#e69875";
    yellow = "#dbbc7f";
    green = "#a7c080";
    aqua = "#83c092";
    blue = "#7fbbb3";
    purple = "#d699b6";
  };
in
{
  inherit raw;

  polarity = "dark";

  # ---- Structure ----
  bg = raw.bg0;
  bgAlt = raw.bgDim;
  bgInset = "#1e2326"; # the theme stops at bgDim; one step darker for insets

  surface = raw.bg1;
  surfaceAlt = raw.bg2;
  surfaceActive = raw.bg4;

  # ---- Foreground ramp ----
  inherit (raw) fg;
  fgDim = raw.grey2;
  fgSubtle = raw.grey1;
  fgMuted = raw.grey0;
  fgFaint = raw.bg5;

  # ---- Lines and emphasis ----
  border = raw.bg3;
  borderActive = raw.green; # the theme's identity colour
  highlight = raw.yellow;

  # ---- Status ----
  error = raw.red;
  warning = raw.yellow;
  success = raw.green;
  info = raw.blue;

  # ---- Distinct hues ----
  hues = {
    inherit (raw) red orange yellow green blue purple;
    cyan = raw.aqua;
    # Everforest has no separate pink/magenta; its purple already sits
    # closest to that hue (as Nord's does for the same reason).
    magenta = raw.purple;
  };
}
