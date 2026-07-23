{ lib }:

rec {
  palettes = import ./palette.nix;

  # Accent names — the subset of a palette that Catppuccin treats as accents
  # (i.e. excludes the greyscale/surface ramp). Used to type jonny.theme.accent.
  accentNames = [
    "rosewater"
    "flamingo"
    "pink"
    "mauve"
    "red"
    "maroon"
    "peach"
    "yellow"
    "green"
    "teal"
    "sky"
    "sapphire"
    "blue"
    "lavender"
  ];

  flavorNames = lib.attrNames palettes;

  # "#cba6f7" -> "cba6f7". swaylock and a few others reject the leading hash.
  stripHash = colour: lib.removePrefix "#" colour;

  # "#cba6f7" -> "cba6f7ff". sway's `client.*` and some CSS want RGBA.
  withAlpha = alpha: colour: "${colour}${alpha}";
}
