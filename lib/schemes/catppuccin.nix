# Catppuccin's four flavours, expressed in the shared role/hue vocabulary.
#
# The native palette is kept in `raw` per flavour so the mapping below stays
# readable — you can see that `surface` is Catppuccin's surface0 — but nothing
# outside this file should reach into `raw`. Modules read roles and hues.
#
# Source: https://github.com/catppuccin/catppuccin

let
  mkFlavour = polarity: raw: {
    inherit polarity raw;

    # ---- Structure ----
    bg = raw.base;
    bgAlt = raw.mantle;
    bgInset = raw.crust;

    surface = raw.surface0;
    surfaceAlt = raw.surface1;
    surfaceActive = raw.surface2;

    # ---- Foreground ramp, brightest first ----
    fg = raw.text;
    fgDim = raw.subtext1;
    fgSubtle = raw.subtext0;
    fgMuted = raw.overlay1;
    fgFaint = raw.overlay0;

    # ---- Lines and emphasis ----
    border = raw.overlay0;
    borderActive = raw.lavender;
    highlight = raw.rosewater; # cursor, selection, link underline

    # ---- Status ----
    error = raw.red;
    warning = raw.yellow;
    success = raw.green;
    info = raw.blue;

    # ---- Distinct hues ----
    # `inherit` where Catppuccin already uses the generic name; the explicit
    # lines are the translations out of its own vocabulary.
    hues = {
      inherit (raw) red yellow green blue;
      orange = raw.peach;
      cyan = raw.teal;
      purple = raw.mauve;
      magenta = raw.pink;
    };
  };
in
{
  latte = mkFlavour "light" {
    rosewater = "#dc8a78";
    flamingo = "#dd7878";
    pink = "#ea76cb";
    mauve = "#8839ef";
    red = "#d20f39";
    maroon = "#e64553";
    peach = "#fe640b";
    yellow = "#df8e1d";
    green = "#40a02b";
    teal = "#179299";
    sky = "#04a5e5";
    sapphire = "#209fb5";
    blue = "#1e66f5";
    lavender = "#7287fd";
    text = "#4c4f69";
    subtext1 = "#5c5f77";
    subtext0 = "#6c6f85";
    overlay2 = "#7c7f93";
    overlay1 = "#8c8fa1";
    overlay0 = "#9ca0b0";
    surface2 = "#acb0be";
    surface1 = "#bcc0cc";
    surface0 = "#ccd0da";
    base = "#eff1f5";
    mantle = "#e6e9ef";
    crust = "#dce0e8";
  };

  frappe = mkFlavour "dark" {
    rosewater = "#f2d5cf";
    flamingo = "#eebebe";
    pink = "#f4b8e4";
    mauve = "#ca9ee6";
    red = "#e78284";
    maroon = "#ea999c";
    peach = "#ef9f76";
    yellow = "#e5c890";
    green = "#a6d189";
    teal = "#81c8be";
    sky = "#99d1db";
    sapphire = "#85c1dc";
    blue = "#8caaee";
    lavender = "#babbf1";
    text = "#c6d0f5";
    subtext1 = "#b5bfe2";
    subtext0 = "#a5adce";
    overlay2 = "#949cbb";
    overlay1 = "#838ba7";
    overlay0 = "#737994";
    surface2 = "#626880";
    surface1 = "#51576d";
    surface0 = "#414559";
    base = "#303446";
    mantle = "#292c3c";
    crust = "#232634";
  };

  macchiato = mkFlavour "dark" {
    rosewater = "#f4dbd6";
    flamingo = "#f0c6c6";
    pink = "#f5bde6";
    mauve = "#c6a0f6";
    red = "#ed8796";
    maroon = "#ee99a0";
    peach = "#f5a97f";
    yellow = "#eed49f";
    green = "#a6da95";
    teal = "#8bd5ca";
    sky = "#91d7e3";
    sapphire = "#7dc4e4";
    blue = "#8aadf4";
    lavender = "#b7bdf8";
    text = "#cad3f5";
    subtext1 = "#b8c0e0";
    subtext0 = "#a5adcb";
    overlay2 = "#939ab7";
    overlay1 = "#8087a2";
    overlay0 = "#6e738d";
    surface2 = "#5b6078";
    surface1 = "#494d64";
    surface0 = "#363a4f";
    base = "#24273a";
    mantle = "#1e2030";
    crust = "#181926";
  };

  mocha = mkFlavour "dark" {
    rosewater = "#f5e0dc";
    flamingo = "#f2cdcd";
    pink = "#f5c2e7";
    mauve = "#cba6f7";
    red = "#f38ba8";
    maroon = "#eba0ac";
    peach = "#fab387";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    teal = "#94e2d5";
    sky = "#89dceb";
    sapphire = "#74c7ec";
    blue = "#89b4fa";
    lavender = "#b4befe";
    text = "#cdd6f4";
    subtext1 = "#bac2de";
    subtext0 = "#a6adc8";
    overlay2 = "#9399b2";
    overlay1 = "#7f849c";
    overlay0 = "#6c7086";
    surface2 = "#585b70";
    surface1 = "#45475a";
    surface0 = "#313244";
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
  };
}
