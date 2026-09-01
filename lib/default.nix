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

  # A keybinding written the way it is spoken — "Mod+Shift+S" — rendered into
  # the form sway's bindsym wants: "Mod4+Shift+s". Each binding is declared
  # once in jonny.desktop.keys and read from there by the sway config, the
  # command menu and the cheatsheet, so a rebind moves all three together
  # instead of leaving two of them lying about the old key.
  swayBinding =
    let
      modifiers = {
        Mod = "Mod4";
        Super = "Mod4";
        Shift = "Shift";
        Ctrl = "Ctrl";
        Alt = "Mod1";
      };

      # sway names punctuation by its X keysym. Letters must be lower case:
      # "Mod4+Shift+S" is a different binding from "Mod4+Shift+s" — it means
      # Shift plus an already-shifted S — and it is not the one any of these
      # are describing.
      keysyms = {
        "." = "period";
        "," = "comma";
        ";" = "semicolon";
        ":" = "colon";
        "?" = "question";
        "-" = "minus";
        "=" = "equal";
        "/" = "slash";
        "`" = "grave";
        "'" = "apostrophe";
        "Space" = "space";
      };
    in
    binding:
    let
      parts = lib.splitString "+" binding;
      key = lib.last parts;
      render = m: modifiers.${m} or (throw "swayBinding: unknown modifier '${m}' in '${binding}'");
      keysym = keysyms.${key}
        or (if lib.stringLength key == 1 then lib.toLower key else key);
    in
    lib.concatStringsSep "+" (map render (lib.init parts) ++ [ keysym ]);
}
