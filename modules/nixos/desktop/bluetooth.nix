{ lib, pkgs, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Installs blueman and its D-Bus/systemd units. The blueman-applet user
    # unit ships without an [Install] section, so it is D-Bus activated only —
    # sway's startup list launches it explicitly (see the compositor module).
    services.blueman.enable = true;

    # Terminal front-end for the same BlueZ stack: scan, pair, trust, connect
    # and toggle adapters without leaving kitty.
    environment.systemPackages = [ pkgs.bluetui ];
  };
}
