{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true; # Steam and 32-bit GL apps
  };
}
