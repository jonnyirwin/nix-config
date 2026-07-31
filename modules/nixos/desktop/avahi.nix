{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  # Shared by ./printing.nix and ./scanning.nix rather than living in either:
  # a network all-in-one is one device announcing several services over the
  # same mDNS, and whichever of the two modules happened to own the daemon
  # would silently be a dependency of the other.
  config = lib.mkIf (cfg.enable && (cfg.printing.enable || cfg.scanning.enable)) {
    services.avahi = {
      enable = true;

      # Resolves `<device>.local` through NSS, so anything that looks up a
      # hostname — not just the print/scan stacks — can address devices by
      # their mDNS name instead of an address a DHCP lease can move.
      #
      # Worth knowing: this does *not* help CUPS. libcups on an Avahi build
      # never falls through to getaddrinfo for `.local`, which is why the
      # printer in hosts/optiplex is declared by its router DNS name. It is
      # sane-airscan's discovery that genuinely depends on this.
      nssmdns4 = true;

      # The firewall is on by default, and mDNS is a conversation rather than
      # a request/response: replies and announcements arrive as multicast to
      # UDP 5353 rather than to the ephemeral port a query went out from, so
      # without the hole open discovery finds nothing at all.
      openFirewall = true;
    };
  };
}
