{ config, lib, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  fonts = config.jonny.theme.fonts;
in
{
  config = lib.mkIf cfg.enable {
    services.mako = {
      enable = true;

      settings = {
        font = "${fonts.ui.family} ${toString fonts.ui.size}";

        background-color = p.surface;
        text-color = p.fg;
        border-color = p.surfaceAlt;
        border-size = 1;
        border-radius = 18;
        progress-color = "over ${p.surfaceAlt}";

        width = 360;
        height = 140;
        padding = 14;
        margin = 8;
        anchor = "top-right";
        layer = "overlay";
        default-timeout = 5000;

        # Dismissed notifications stay recoverable with `makoctl restore`,
        # bound to Mod+Shift+, in the sway config. mako's default of 5 is
        # short enough that a busy minute loses the thing you meant to read.
        max-history = 20;

        icons = true;
        max-icon-size = 48;
        markup = true;

        format = ''<span foreground="${p.accent}" weight="bold">%s</span>\n<span foreground="${p.fgDim}">%b</span>'';

        "urgency=low" = {
          border-color = p.border;
          default-timeout = 3000;
          format = ''<span foreground="${p.border}" weight="bold">%s</span>\n<span foreground="${p.fgDim}">%b</span>'';
        };

        "urgency=high" = {
          border-color = p.error;
          default-timeout = 0; # critical notifications stay until dismissed
          format = ''<span foreground="${p.error}" weight="bold">%s</span>\n<span foreground="${p.fgDim}">%b</span>'';
        };
      };
    };
  };
}
