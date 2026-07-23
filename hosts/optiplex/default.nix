{ inputs, ... }:

# ============================================================
# Host: optiplex — Dell OptiPlex 3000, Intel i3-12100T (Alder Lake)
# ============================================================
# Encrypted (LUKS) root + encrypted swap; UEFI / systemd-boot.
# Everything here is either a hardware fact or a deliberate per-host choice;
# shared behaviour lives in modules/nixos.
{
  imports = with inputs.nixos-hardware.nixosModules; [
    ./hardware.nix

    # Hardware detected rather than guessed. Regenerate after a hardware
    # change with:
    #   sudo nix run nixpkgs#nixos-facter -- -o hosts/optiplex/facter.json
    #
    # This currently runs *alongside* the generated hardware.nix — the two
    # only set list-valued options, which merge. hardware.nix goes away at the
    # disk migration, when disko takes over the filesystem half of it.
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }

    # Community hardware profiles — see github.com/NixOS/nixos-hardware.
    # common-cpu-intel pulls in the Intel GPU profile, which is considerably
    # more thorough than hand-rolling it: 32-bit VA-API, the compute runtime,
    # i915/xe driver selection, and an assertion against too-old kernels.
    common-cpu-intel
    common-pc
    common-pc-ssd # NVMe + SATA SSD; enables periodic fstrim
  ];

  jonny = {
    desktop = {
      enable = true;
      compositor = "sway";
    };
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
