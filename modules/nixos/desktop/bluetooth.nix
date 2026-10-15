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

    # The MT7921's passive background scan sometimes stops reporting bonded
    # LE keyboards after they've been off for a while, so the Eidolon never
    # reconnects on power-on even though it's advertising and on the kernel's
    # auto-connect list. A short active LE scan makes BlueZ see it and connect
    # immediately — so run one every 30s while a listed device is
    # disconnected. Devices not paired on this host are skipped.
    systemd.services.bluetooth-le-reconnect = {
      description = "Nudge disconnected Bluetooth LE keyboards to reconnect";
      after = [ "bluetooth.service" ];
      requires = [ "bluetooth.service" ];
      wantedBy = [ "bluetooth.target" ];
      serviceConfig.Restart = "always";
      path = [ pkgs.bluez pkgs.gnugrep pkgs.coreutils ];
      script = ''
        devices=(
          D1:92:9E:5F:75:73 # Eidolon
        )
        while true; do
          for mac in "''${devices[@]}"; do
            info=$(bluetoothctl info "$mac") || continue
            if ! grep -q "Connected: yes" <<<"$info"; then
              bluetoothctl --timeout 5 scan le >/dev/null 2>&1 || true
              break
            fi
          done
          sleep 25
        done
      '';
    };

    # Terminal front-end for the same BlueZ stack: scan, pair, trust, connect
    # and toggle adapters without leaving kitty.
    environment.systemPackages = [ pkgs.bluetui ];
  };
}
