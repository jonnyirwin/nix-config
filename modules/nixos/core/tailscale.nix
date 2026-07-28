{ lib, config, ... }:

let
  cfg = config.jonny.services.tailscale;
in
{
  options.jonny.services.tailscale = {
    enable = lib.mkEnableOption "the Tailscale client daemon";

    trustTailnet = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Add the Tailscale interface to `networking.firewall.trustedInterfaces`,
        which exempts tailnet traffic from the firewall entirely.

        Off by default, because it is a bigger grant than it looks: it exposes
        *every* listening service on this machine to every device on the
        tailnet, not just the ones with an open port. Reaching SSH over the
        tailnet does not need it — `services.openssh` already opens 22 — so
        turn it on only when you want the tailnet treated as a LAN, and
        remember that a phone with the Tailscale app counts as a tailnet
        device.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;

      # Opens UDP 41641 so peers can establish a direct connection to this
      # machine. Without it Tailscale still works, but connections that cannot
      # hole-punch fall back to relaying through Tailscale's DERP servers,
      # which adds latency and puts a third party in the data path. The port
      # only ever accepts authenticated WireGuard traffic, so opening it is a
      # performance fix rather than a meaningful widening of the attack
      # surface.
      openFirewall = true;

      # "client" rather than the "none" default: it is what lets this machine
      # *use* an exit node or a subnet router, and it relaxes reverse path
      # filtering from strict to loose. Strict rpfilter drops replies arriving
      # on tailscale0 for traffic that left via the physical NIC, which is
      # exactly the pattern exit-node routing produces — the failure looks
      # like a tailnet that pings but carries no traffic.
      #
      # Deliberately not "server"/"both": those enable IP forwarding, which
      # this desktop only needs if it starts advertising routes for the rest
      # of the LAN. Change it here if that day comes.
      useRoutingFeatures = "client";
    };

    networking.firewall.trustedInterfaces =
      lib.mkIf cfg.trustTailnet [ config.services.tailscale.interfaceName ];
  };
}
