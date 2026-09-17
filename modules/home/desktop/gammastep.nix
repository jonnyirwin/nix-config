{ config, lib, ... }:

let
  cfg = config.jonny.desktop;
in
{
  # Warms the display colour temperature after dusk. Compositor-agnostic:
  # gammastep picks the wlr-gamma-control protocol itself, so nothing here
  # depends on which compositor jonny.desktop.compositor names.
  #
  # The unit ships WantedBy=graphical-session.target, which sway-session.target
  # BindsTo, so it comes up with the session without the `targets` wiring
  # waybar.nix needs.
  config = lib.mkIf cfg.enable {
    services.gammastep = {
      enable = true;

      # Douglas, Isle of Man. Manual rather than provider = "geoclue2": geoclue
      # wants a system service plus an agent allowlist entry and a working
      # network just to work out the time of day. Sunset is derived from these,
      # so the schedule follows the seasons on its own.
      provider = "manual";
      latitude = 54.15;
      longitude = -4.48;

      temperature = {
        day = 6500; # neutral — daylight hours are left alone
        night = 3400;
      };
    };
  };
}
