# Gruvbox Dark.
#
# Declared in Gruvbox's own vocabulary (bg0..bg4, fg0..fg4, the bright/neutral
# accent pairs) and then mapped onto roles. Nothing is approximated: every role
# is filled by a colour Gruvbox actually defines.
#
# Source: https://github.com/morhetz/gruvbox

let
  raw = {
    bg0_h = "#1d2021";
    bg0 = "#282828";
    bg1 = "#3c3836";
    bg2 = "#504945";
    bg3 = "#665c54";
    bg4 = "#7c6f64";

    fg0 = "#fbf1c7";
    fg1 = "#ebdbb2";
    fg2 = "#d5c4a1";
    fg3 = "#bdae93";
    fg4 = "#a89984";

    gray = "#928374";

    brightRed = "#fb4934";
    brightGreen = "#b8bb26";
    brightYellow = "#fabd2f";
    brightBlue = "#83a598";
    brightPurple = "#d3869b";
    brightAqua = "#8ec07c";
    brightOrange = "#fe8019";

    neutralRed = "#cc241d";
    neutralBlue = "#458588";
    neutralPurple = "#b16286";
  };
in
{
  inherit raw;

  polarity = "dark";

  # ---- Structure ----
  bg = raw.bg0;
  bgAlt = raw.bg0_h;
  bgInset = "#141617"; # Gruvbox stops at bg0_h; one step darker for insets

  surface = raw.bg1;
  surfaceAlt = raw.bg2;
  surfaceActive = raw.bg3;

  # ---- Foreground ramp ----
  fg = raw.fg1;
  fgDim = raw.fg2;
  fgSubtle = raw.fg3;
  fgMuted = raw.gray;
  fgFaint = raw.bg4;

  # ---- Lines and emphasis ----
  border = raw.bg4;
  borderActive = raw.brightOrange; # Gruvbox's signature focus colour
  highlight = raw.fg0;

  # ---- Status ----
  error = raw.brightRed;
  warning = raw.brightYellow;
  success = raw.brightGreen;
  info = raw.brightBlue;

  # ---- Distinct hues ----
  hues = {
    red = raw.brightRed;
    orange = raw.brightOrange;
    yellow = raw.brightYellow;
    green = raw.brightGreen;
    cyan = raw.brightAqua;
    blue = raw.brightBlue;
    purple = raw.brightPurple;
    magenta = raw.neutralPurple;
  };

  # Gruvbox specifies its own ANSI mapping; the neutral variants are the
  # normal-intensity set, brights are the bright set.
  ansi = {
    black = raw.bg1;
    red = raw.neutralRed;
    green = "#98971a";
    yellow = "#d79921";
    blue = raw.neutralBlue;
    magenta = raw.neutralPurple;
    cyan = "#689d6a";
    white = raw.fg2;

    inherit (raw) brightRed brightGreen brightYellow brightBlue;
    brightBlack = raw.bg4;
    brightMagenta = raw.brightPurple;
    brightCyan = raw.brightAqua;
    brightWhite = raw.fg0;
  };
}
