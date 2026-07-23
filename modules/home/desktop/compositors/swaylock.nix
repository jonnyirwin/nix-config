{ config, lib, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  fonts = config.jonny.theme.fonts;

  # swaylock rejects the leading '#'.
  bare = lib.removePrefix "#";
in
{
  config = lib.mkIf (cfg.enable && cfg.compositor == "sway") {
    programs.swaylock = {
      enable = true;

      settings = {
        font = fonts.ui.family;
        font-size = 36;
        scaling = "fill";

        indicator-caps-lock = true;
        indicator-radius = 200;
        indicator-thickness = 20;
        show-failed-attempts = true;

        # Default — accent ring on a transparent fill.
        ring-color = bare p.accent;
        key-hl-color = bare p.success;
        bs-hl-color = bare p.error;
        inside-color = "00000000";
        line-color = bare p.bgAlt;
        text-color = bare p.fg;
        separator-color = "00000000";

        # Verifying
        ring-ver-color = bare p.accent;
        inside-ver-color = "00000000";
        line-ver-color = bare p.bgAlt;
        text-ver-color = bare p.accent;

        # Wrong password
        ring-wrong-color = bare p.error;
        inside-wrong-color = "00000000";
        line-wrong-color = bare p.bgAlt;
        text-wrong-color = bare p.error;

        # Cleared (escape)
        ring-clear-color = bare p.hues.orange;
        inside-clear-color = "00000000";
        line-clear-color = bare p.bgAlt;
        text-clear-color = bare p.hues.orange;

        # Caps lock
        ring-caps-lock-color = bare p.warning;
        caps-lock-key-hl-color = bare p.success;
        caps-lock-bs-hl-color = bare p.error;
        text-caps-lock-color = bare p.warning;
      };
    };
  };
}
