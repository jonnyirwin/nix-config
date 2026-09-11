# Kanagawa ("Wave" variant — the theme's default background).
#
# Declared in the theme's own vocabulary (the sumiInk ramp, fujiWhite/oldWhite/
# fujiGray, and its named accent colours) and mapped onto roles.
#
# Source: https://github.com/rebelot/kanagawa.nvim

let
  raw = {
    sumiInk0 = "#16161d";
    sumiInk1 = "#181820";
    sumiInk3 = "#1f1f28"; # editor background
    sumiInk4 = "#2a2a37";
    sumiInk5 = "#363646";
    sumiInk6 = "#54546d";

    fujiWhite = "#dcd7ba";
    oldWhite = "#c8c093";
    fujiGray = "#727169";

    autumnRed = "#c34043";
    surimiOrange = "#ffa066";
    carpYellow = "#e6c384";
    springGreen = "#98bb6c";
    waveAqua2 = "#7aa89f";
    crystalBlue = "#7e9cd8";
    oniViolet = "#957fb8";
    sakuraPink = "#d27e99";
  };
in
{
  inherit raw;

  polarity = "dark";

  # ---- Structure ----
  bg = raw.sumiInk3;
  bgAlt = raw.sumiInk0;
  bgInset = "#0f0f14"; # the theme stops at sumiInk0; one step darker for insets

  surface = raw.sumiInk4;
  surfaceAlt = raw.sumiInk5;
  surfaceActive = raw.sumiInk6;

  # ---- Foreground ramp ----
  fg = raw.fujiWhite;
  fgDim = raw.oldWhite;
  # The theme names only three foreground tones (fujiWhite, oldWhite,
  # fujiGray); this one fills the gap between them, the same way sumiInk0's
  # bgInset above extends a ramp the theme itself stops short of.
  fgSubtle = "#a6a186";
  fgMuted = raw.fujiGray;
  fgFaint = raw.sumiInk6;

  # ---- Lines and emphasis ----
  border = raw.sumiInk5;
  borderActive = raw.crystalBlue; # the theme's signature accent
  highlight = raw.sakuraPink;

  # ---- Status ----
  error = raw.autumnRed;
  warning = raw.carpYellow;
  success = raw.springGreen;
  info = raw.crystalBlue;

  # ---- Distinct hues ----
  hues = {
    red = raw.autumnRed;
    orange = raw.surimiOrange;
    yellow = raw.carpYellow;
    green = raw.springGreen;
    cyan = raw.waveAqua2;
    blue = raw.crystalBlue;
    purple = raw.oniViolet;
    magenta = raw.sakuraPink;
  };
}
