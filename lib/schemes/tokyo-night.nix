# Tokyo Night ("Night" variant — the plugin's default, deep navy dark theme).
#
# Declared in the theme's own vocabulary (a stack of blue-tinted greys, plus
# the named accent colours) and mapped onto roles.
#
# Source: https://github.com/folke/tokyonight.nvim

let
  raw = {
    bgDark = "#16161e";
    bg = "#1a1b26";
    bgHighlight = "#292e42";
    fgGutter = "#3b4261";
    terminalBlack = "#414868";
    dark3 = "#545c7e";
    comment = "#565f89";
    dark5 = "#737aa2";
    fgDark = "#a9b1d6";
    fg = "#c0caf5";

    red = "#f7768e";
    orange = "#ff9e64";
    yellow = "#e0af68";
    green = "#9ece6a";
    cyan = "#7dcfff";
    blue = "#7aa2f7";
    purple = "#9d7cd8";
    magenta = "#bb9af7";
    magenta2 = "#ff007c"; # a hotter pink used for special highlights/search
  };
in
{
  inherit raw;

  polarity = "dark";

  # ---- Structure ----
  inherit (raw) bg;
  bgAlt = raw.bgDark;
  bgInset = "#101014"; # the theme stops at bgDark; one step darker for insets

  surface = raw.bgHighlight;
  surfaceAlt = raw.fgGutter;
  surfaceActive = raw.terminalBlack;

  # ---- Foreground ramp ----
  inherit (raw) fg;
  fgDim = raw.fgDark;
  fgSubtle = raw.dark5;
  fgMuted = raw.comment;
  fgFaint = raw.dark3;

  # ---- Lines and emphasis ----
  border = raw.fgGutter; # the theme's own vertsplit/border colour
  borderActive = raw.blue; # Tokyo Night's signature accent
  highlight = raw.magenta2;

  # ---- Status ----
  error = raw.red;
  warning = raw.yellow;
  success = raw.green;
  info = raw.blue;

  # ---- Distinct hues ----
  hues = {
    inherit (raw) red orange yellow green cyan blue purple magenta;
  };

  # The theme ships its own terminal palette, distinct enough from a pure
  # role-derivation (its ANSI black/white sit outside the surface/fg ramp
  # above) that it is worth stating rather than deriving.
  ansi = {
    black = "#15161e";
    inherit (raw) red green yellow blue magenta cyan;
    white = raw.fgDark;

    brightBlack = raw.terminalBlack;
    brightRed = raw.red;
    brightGreen = raw.green;
    brightYellow = raw.yellow;
    brightBlue = raw.blue;
    brightMagenta = raw.magenta;
    brightCyan = raw.cyan;
    brightWhite = raw.fg;
  };
}
