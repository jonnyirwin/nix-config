{ config, lib, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  font = config.jonny.theme.font;

  # swaylock rejects the leading '#'.
  bare = lib.removePrefix "#";
in
{
  config = lib.mkIf cfg.enable {
    programs.swaylock = {
      enable = true;

      settings = {
        font = font.family;
        font-size = 36;
        scaling = "fill";

        indicator-caps-lock = true;
        indicator-radius = 200;
        indicator-thickness = 20;
        show-failed-attempts = true;

        # Default — accent ring on a transparent fill.
        ring-color = bare p.accent;
        key-hl-color = bare p.green;
        bs-hl-color = bare p.red;
        inside-color = "00000000";
        line-color = bare p.mantle;
        text-color = bare p.text;
        separator-color = "00000000";

        # Verifying
        ring-ver-color = bare p.accent;
        inside-ver-color = "00000000";
        line-ver-color = bare p.mantle;
        text-ver-color = bare p.accent;

        # Wrong password
        ring-wrong-color = bare p.red;
        inside-wrong-color = "00000000";
        line-wrong-color = bare p.mantle;
        text-wrong-color = bare p.red;

        # Cleared (escape)
        ring-clear-color = bare p.peach;
        inside-clear-color = "00000000";
        line-clear-color = bare p.mantle;
        text-clear-color = bare p.peach;

        # Caps lock
        ring-caps-lock-color = bare p.yellow;
        caps-lock-key-hl-color = bare p.green;
        caps-lock-bs-hl-color = bare p.red;
        text-caps-lock-color = bare p.yellow;
      };
    };
  };
}
