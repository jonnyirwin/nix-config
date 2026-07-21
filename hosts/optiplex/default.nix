{ config, pkgs, lib, ... }:

# ============================================================
# Host: optiplex — Dell OptiPlex desktop (Intel)
# ============================================================
# Migrated from the fresh NixOS 26.05 install's /etc/nixos.
# Encrypted (LUKS) root + encrypted swap; UEFI / systemd-boot.
{
  imports = [
    ./hardware.nix
    # Desktop machine — no laptop power/touchpad module.
  ];

  networking.hostName = "optiplex";

  # ── Boot ───────────────────────────────────────────────────
  # Standard UEFI PC: systemd-boot may write EFI variables.
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Secondary data drive ───────────────────────────────────
  # 512 GB Samsung NVMe (nvme0n1p1), ext4, unencrypted. Kept here
  # rather than in the generated hardware.nix so it survives a
  # nixos-generate-config regen. `nofail` + a short device timeout
  # mean a missing/failed drive never blocks boot.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/68a6be10-d9d7-455c-9566-c8da66238360";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=5s" ];
  };

  # ── Disk encryption ────────────────────────────────────────
  # Root LUKS unlock lives in hardware.nix (generated).
  # The encrypted *swap* unlock was defined in the old
  # /etc/nixos/configuration.nix — carried over here so swap
  # is opened at boot.
  boot.initrd.luks.devices."luks-3f374acb-7aaf-4c5d-9b48-fac6c449931f".device =
    "/dev/disk/by-uuid/3f374acb-7aaf-4c5d-9b48-fac6c449931f";

  # ── State version ──────────────────────────────────────────
  # This machine was first installed on NixOS 26.05. common.nix sets a
  # shared "24.11"; mkForce overrides it for this host to match the install.
  system.stateVersion = lib.mkForce "26.05";

  # Machine-specific packages (system-level — prefer HM for user packages).
  environment.systemPackages = [ ];
}
