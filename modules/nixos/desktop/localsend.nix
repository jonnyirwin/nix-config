{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # System-level rather than a Home Manager package because the useful half
    # of LocalSend is the firewall hole, not the binary: peers find each other
    # over UDP multicast on 53317 and then transfer over TCP 53317, and the
    # firewall is on by default, so a user-profile install would show an empty
    # peer list and refuse every incoming send.
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
}
