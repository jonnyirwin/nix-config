{ lib, config, ... }:

let
  cfg = config.jonny.services.openssh;

  isV6 = lib.hasInfix ":";
  allowFrom = subnet:
    "${if isV6 subnet then "ip6tables" else "iptables"} -A nixos-fw -p tcp --dport 22 -s ${subnet} -j nixos-fw-accept";
in
{
  options.jonny.services.openssh = {
    enable = lib.mkEnableOption "the OpenSSH daemon (key auth only, no root login)";

    lanSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "192.168.1.0/24" "fe80::/10" ];
      description = ''
        Source ranges, besides the tailnet, allowed to reach port 22.

        By address rather than by interface: the LAN interface also carries
        the machine's public IPv6 traffic, so "allow enp2s0" would let the
        whole internet in wherever the router's IPv6 firewall doesn't stop it.

        Empty by default, so SSH is tailnet-only. Leave it that way on a
        laptop — a cafe network hands out the same 192.168.x ranges as home,
        and a LAN rule would admit everyone sitting there.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "no";

      # Not opened on every interface; see the rules below.
      openFirewall = false;
    };

    networking.firewall = {
      interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ 22 ];
      extraCommands = lib.concatMapStringsSep "\n" allowFrom cfg.lanSubnets;
    };
  };
}
