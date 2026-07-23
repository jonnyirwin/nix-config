{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true; # pactl and pulsemixer talk to this shim
    };

    services.pulseaudio.enable = false; # replaced by pipewire
    security.rtkit.enable = true; # lets pipewire request realtime priority
  };
}
