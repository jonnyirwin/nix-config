{ ... }:

# ============================================================
# Host: optiplex — Dell OptiPlex desktop (Intel)
# ============================================================
# Encrypted (LUKS) root + encrypted swap; UEFI / systemd-boot.
# Everything here is either a hardware fact or a deliberate per-host choice;
# shared behaviour lives in modules/nixos.
{
  imports = [ ./hardware.nix ];

  networking.hostName = "optiplex";

  jonny = {
    desktop.enable = true;
    hardware.intel.enable = true;
    services.openssh.enable = true;
    secrets.enable = true;
    security.passwordlessSudo = true;
  };

  boot = {
    # ── Boot ─────────────────────────────────────────────────
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    # ── Disk encryption ──────────────────────────────────────
    # Root LUKS unlock lives in the generated hardware.nix; this is the
    # encrypted *swap* device, which nixos-generate-config does not emit.
    initrd.luks.devices."luks-3f374acb-7aaf-4c5d-9b48-fac6c449931f".device =
      "/dev/disk/by-uuid/3f374acb-7aaf-4c5d-9b48-fac6c449931f";
  };

  # ── Secondary data drive ───────────────────────────────────
  # 512 GB Samsung NVMe (nvme0n1p1), ext4, unencrypted. Kept here rather than in
  # the generated hardware.nix so it survives a nixos-generate-config regen.
  # `nofail` + a short device timeout mean a missing drive never blocks boot.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/68a6be10-d9d7-455c-9566-c8da66238360";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=5s" ];
  };

  # First installed on NixOS 26.05. Never bump this to "upgrade" — it selects
  # backwards-compatibility defaults for stateful services.
  system.stateVersion = "26.05";
}
