{ lib, ... }:

{
  networking = {
    networkmanager.enable = true;

    # NetworkManager is the only DHCP client.
    #
    # nixos-facter enumerates the machine's interfaces into
    # `networking.interfaces.*`, and NixOS reads a non-empty set of those as
    # "configure these with dhcpcd" — which pulls dhcpcd.service into
    # multi-user.target alongside NetworkManager. Two DHCP clients on one link
    # means lease fights and intermittent connectivity, so switch it off
    # explicitly rather than relying on it staying off by accident.
    useDHCP = false;
    dhcpcd.enable = lib.mkForce false;
  };
}
