{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.jonny.desktop;
in
{
  options.jonny.desktop.airplay.enable =
    lib.mkEnableOption "AirPlay mirroring receiver (UxPlay, run on demand with `uxplay -p`)";

  config = lib.mkIf (cfg.enable && cfg.airplay.enable) {
    environment.systemPackages = [ pkgs.uxplay ];

    # The daemon itself lives in ./avahi.nix. Printing and scanning only ever
    # browse, but a receiver has to announce itself, and UxPlay registers its
    # AirPlay services through Avahi's client API, which is what userServices
    # permits. Without this the iPhone's Screen Mirroring list stays empty.
    services.avahi.publish = {
      enable = true;
      userServices = true;
    };

    # UxPlay picks random ports unless told otherwise; `-p` pins it to exactly
    # these, which is what makes a static firewall hole possible.
    networking.firewall = {
      allowedTCPPorts = [
        7000
        7001
        7100
      ];
      allowedUDPPorts = [
        6000
        6001
        7011
      ];
    };
  };
}
