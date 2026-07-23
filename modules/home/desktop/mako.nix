{ config, lib, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  font = config.jonny.theme.font;
in
{
  config = lib.mkIf cfg.enable {
    services.mako = {
      enable = true;

      settings = {
        font = "${font.family} ${toString font.size}";

        background-color = p.surface0;
        text-color = p.text;
        border-color = p.surface1;
        border-size = 1;
        border-radius = 18;
        progress-color = "over ${p.surface1}";

        width = 360;
        height = 140;
        padding = 14;
        margin = 8;
        anchor = "top-right";
        layer = "overlay";
        default-timeout = 5000;

        icons = true;
        max-icon-size = 48;
        markup = true;

        format = ''<span foreground="${p.accent}" weight="bold">%s</span>\n<span foreground="${p.subtext1}">%b</span>'';

        "urgency=low" = {
          border-color = p.overlay0;
          default-timeout = 3000;
          format = ''<span foreground="${p.overlay0}" weight="bold">%s</span>\n<span foreground="${p.subtext1}">%b</span>'';
        };

        "urgency=high" = {
          border-color = p.red;
          default-timeout = 0; # critical notifications stay until dismissed
          format = ''<span foreground="${p.red}" weight="bold">%s</span>\n<span foreground="${p.subtext1}">%b</span>'';
        };
      };
    };
  };
}
