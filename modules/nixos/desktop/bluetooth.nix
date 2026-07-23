{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;
  };
}
