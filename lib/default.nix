{ lib }:

rec {
  schemes = import ./schemes { inherit lib; };

  schemeNames = lib.attrNames schemes;

  # Accents are chosen by hue, not by a scheme's brand name for a colour — so
  # `accent = "purple"` means the same thing in Catppuccin, Gruvbox and Nord,
  # and switching scheme keeps your accent choice meaningful.
  accentNames = [
    "red"
    "orange"
    "yellow"
    "green"
    "cyan"
    "blue"
    "purple"
    "magenta"
  ];

  # Schemes the catppuccin/nix HM modules can theme directly. For anything else
  # those modules are switched off and the program is themed from the palette.
  catppuccinFlavors = {
    catppuccin-latte = "latte";
    catppuccin-frappe = "frappe";
    catppuccin-macchiato = "macchiato";
    catppuccin-mocha = "mocha";
  };

  # The accent name catppuccin/nix expects, which uses its own vocabulary.
  catppuccinAccents = {
    red = "red";
    orange = "peach";
    yellow = "yellow";
    green = "green";
    cyan = "teal";
    blue = "blue";
    purple = "mauve";
    magenta = "pink";
  };

  # Syntax-highlighting theme per scheme, for programs carrying their own named
  # theme sets rather than accepting raw colours — bat, and delta through it.
  # bat ships Nord and gruvbox-dark; the Catppuccin ones come from
  # catppuccin.bat.enable.
  batThemes = {
    catppuccin-latte = "Catppuccin Latte";
    catppuccin-frappe = "Catppuccin Frappe";
    catppuccin-macchiato = "Catppuccin Macchiato";
    catppuccin-mocha = "Catppuccin Mocha";
    gruvbox-dark = "gruvbox-dark";
    nord = "Nord";
  };

  # "#cba6f7" -> "cba6f7". swaylock and a few others reject the leading hash.
  stripHash = lib.removePrefix "#";
}
