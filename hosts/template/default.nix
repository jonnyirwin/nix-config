{ config, pkgs, lib, ... }:

# ============================================================
# Host template — copy to hosts/<hostname>/default.nix
# ============================================================
# Steps to bootstrap a new machine:
#   1. Boot the NixOS installer
#   2. Run: nixos-generate-config --show-hardware-config > hardware.nix
#      and commit it alongside this file
#   3. Set networking.hostName below
#   4. Uncomment laptop.nix if this is a portable machine
#   5. Deploy: nixos-rebuild switch --flake ~/git/nix#<hostname>
# ============================================================
{
  imports = [
    ./hardware.nix

    # Uncomment for laptops:
    # ../../nixos-modules/hardware/laptop.nix

    # Uncomment for machines with an Nvidia GPU:
    # ../../nixos-modules/hardware/nvidia.nix
  ];

  networking.hostName = "CHANGEME";

  # Machine-specific packages (system-level — prefer HM for user packages).
  environment.systemPackages = [ ];
}
