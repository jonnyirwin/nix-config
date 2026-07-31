{ lib, pkgs, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  options.jonny.desktop.scanning.enable =
    lib.mkEnableOption "scanning (SANE, driverless eSCL over the network)";

  config = lib.mkIf (cfg.enable && cfg.scanning.enable) {
    hardware.sane = {
      enable = true;

      # eSCL / AirScan — the scanning half of what makes a modern all-in-one
      # driverless. The scanner is an HTTP service on the device (the ENVY
      # 4520 advertises _uscan._tcp on port 8080) that returns JPEG or PDF, so
      # there is no vendor backend involved and nothing to keep working across
      # a SANE bump.
      #
      # This is why there is no `pkgs.hplipWithPlugin` here. That is the
      # traditional answer for an HP all-in-one and it would work, but it
      # means a large closure and a binary blob to do what the device already
      # exposes over standard HTTP.
      extraBackends = [ pkgs.sane-airscan ];

      # Deliberately not `openFirewall`. Despite the name it opens UDP 8612,
      # which is Canon's BJNP discovery protocol and nothing to do with eSCL —
      # airscan finds devices over mDNS, which Avahi already covers.
    };

    # No `scanner`/`lp` group membership needed. Those exist so that a *USB*
    # scanner's device node is readable by a normal user; a network scanner
    # has no device node, and airscan just talks HTTP to the printer's
    # address. Add jonny to `scanner` only if a USB scanner ever appears.

    # GNOME's Document Scanner: the sane-airscan device shows up in it with no
    # configuration. `scanimage -L` from the CLI sees the same device.
    environment.systemPackages = [ pkgs.simple-scan ];
  };
}
