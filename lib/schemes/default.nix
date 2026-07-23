{ lib }:

# Colour schemes.
#
# A scheme is described in two layers, and modules read whichever fits:
#
#   ROLES — what a colour is *for*. Structure: backgrounds, surfaces, the
#   foreground ramp, borders, and the four status colours. A module asking for
#   `bg` or `error` gets something sensible from any scheme, and the name says
#   what it does.
#
#   HUES — eight generic colour terms (red orange yellow green cyan blue purple
#   magenta). For the cases that genuinely want N visually distinct colours:
#   waybar's per-module colours, kitty's marks, terminal ANSI. These are the
#   names every palette defines in some form, so nothing has to be invented.
#
# Deliberately NOT used: a scheme's own brand vocabulary. Catppuccin's
# "rosewater"/"sapphire"/"mauve" have no equivalent in Gruvbox or Nord, so
# forcing other palettes into those slots means inventing colours that were
# never designed — which is exactly what this layout avoids.
#
# To add a scheme: write <name>.nix returning the role and hue keys, and list
# it below. ANSI is derived unless the scheme overrides it.

let
  # Terminals need the 16 ANSI slots. Deriving them from roles + hues keeps
  # scheme files to what is actually scheme-specific; a scheme with unusual
  # terminal colours can still set `ansi` itself to override.
  withAnsi = scheme: scheme // {
    ansi = {
      black = scheme.surfaceAlt;
      red = scheme.hues.red;
      green = scheme.hues.green;
      yellow = scheme.hues.yellow;
      blue = scheme.hues.blue;
      magenta = scheme.hues.magenta;
      cyan = scheme.hues.cyan;
      white = scheme.fgDim;

      brightBlack = scheme.surfaceActive;
      brightRed = scheme.hues.red;
      brightGreen = scheme.hues.green;
      brightYellow = scheme.hues.yellow;
      brightBlue = scheme.hues.blue;
      brightMagenta = scheme.hues.magenta;
      brightCyan = scheme.hues.cyan;
      brightWhite = scheme.fgSubtle;
    } // (scheme.ansi or { });
  };

  catppuccin = import ./catppuccin.nix;
in
lib.mapAttrs (_: withAnsi) {
  catppuccin-latte = catppuccin.latte;
  catppuccin-frappe = catppuccin.frappe;
  catppuccin-macchiato = catppuccin.macchiato;
  catppuccin-mocha = catppuccin.mocha;

  gruvbox-dark = import ./gruvbox-dark.nix;
  nord = import ./nord.nix;
}
