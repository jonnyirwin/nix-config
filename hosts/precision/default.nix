{ inputs, lib, ... }:

# ============================================================
# Host: precision — Dell Precision T1700 Mini Tower, Intel i7-4790 (Haswell)
# ============================================================
# 16 GB RAM, UEFI. Two disks: a 256 GB SSD that this config owns, and a 2 TB
# archive disk that it deliberately does not — see ./disks/default.nix.
#
# Graphics are the Haswell iGPU only. The machine also has an NVIDIA Quadro
# K600, which is switched off rather than driven; see the GPU note below.
{
  imports = with inputs.nixos-hardware.nixosModules; [
    # Disks. ./disks declares the OS SSD only, and disko derives fileSystems,
    # swapDevices and the LUKS unlock from it. The 2 TB archive disk is
    # mounted further down instead, and is intentionally not disko's to touch.
    #
    # WARNING: these mounts do not exist until ./disks has been applied.
    inputs.disko.nixosModules.disko
    ./disks

    # Hardware detected rather than guessed. Regenerate after a hardware
    # change with:
    #   sudo nix run nixpkgs#nixos-facter -- -o hosts/precision/facter.json
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }

    # nixos-hardware has dell/precision profiles, but only for models this is
    # not (3490, 3541, 5490, 5530, 5560, 5570, 5820, 7520) — all laptops or
    # much later workstations. So this takes the same generic three optiplex
    # does, which is what those profiles would mostly have provided anyway.
    common-cpu-intel
    common-pc
    common-pc-ssd
  ];

  jonny = {
    desktop = {
      enable = true;
      compositor = "sway";

      # No `greeter` block and no per-output config: nothing is plugged in at
      # the moment, so there is no layout worth pinning yet. Add one once a
      # monitor is attached and you know the output name — and see the GPU
      # note below about *which* port it needs to be attached to.
    };

    theme = {
      scheme = "catppuccin-mocha";
      accent = "purple";
    };

    services.openssh.enable = true;
    services.tailscale.enable = true;
    security.passwordlessSudo = true;

    # Stays off until the machine has booted once — the sops identity is this
    # host's SSH host key, which does not exist yet. After first boot, follow
    # the three steps in .sops.yaml, create secrets/precision.yaml, then
    # uncomment.
    # secrets.enable = true;
  };

  boot = {
    # ── GPU ──────────────────────────────────────────────────
    # Intel Haswell integrated graphics only. The Quadro K600 in the slot is
    # Kepler, which current nixpkgs supports only through nvidia's legacy_470
    # branch — a driver that trails kernel releases and would make this the
    # one machine in the fleet that cannot take a kernel bump freely. An
    # HD 4600 drives a sway desktop perfectly well, so the card buys nothing.
    #
    # nouveau is blacklisted rather than merely unused: with both cards
    # visible the compositor can pick the wrong DRM node, and an unbound card
    # is a clearer state than a bound one nothing renders on.
    #
    # IMPORTANT, and not something this file can enforce: the monitor must be
    # plugged into the *motherboard's* outputs (DP-1/DP-2/HDMI/VGA on card0),
    # not the Quadro's (DP-3/DVI-I-1 on card1). Some Dell workstation firmware
    # also disables the iGPU whenever a discrete card is fitted — if there is
    # no display on the onboard ports, either enable integrated graphics in
    # the BIOS or pull the card.
    blacklistedKernelModules = [ "nouveau" ];

    # For the archive disk mounted below. ntfs3 is the in-kernel driver
    # rather than the ntfs-3g FUSE one: faster, and no userspace daemon in
    # the boot path.
    supportedFilesystems = [ "ntfs" ];

    # ── Boot ─────────────────────────────────────────────────
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 20;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  # ── Archive disk ───────────────────────────────────────────
  # The 2 TB Seagate, mounted rather than managed. It stays NTFS because that
  # is what it already is and reformatting it would mean moving 1.2 TB with
  # nowhere to move it to.
  #
  # This is the deliberate exception to letting disko own every mount — see
  # the long note in ./disks/default.nix. It is written by hand precisely
  # because disko must never see this device.
  #
  # NTFS carries no Unix ownership, so uid/gid are assigned at mount time;
  # 1000/100 is jonny/users, matching what NixOS assigns the first normal user.
  #
  # Worth knowing: NTFS writes under Linux are less battle-tested than reads.
  # Treat this as an archive to read from, and prefer moving anything actively
  # edited onto the encrypted root.
  fileSystems."/mnt/archive" = {
    device = "/dev/disk/by-id/ata-ST2000DM001-1CH164_W1E8BNXJ-part1";
    fsType = "ntfs3";
    options = [
      "uid=1000"
      "gid=100"
      "umask=0022"
      # Never block boot on the archive disk. Debian mounted this at
      # /mnt/sdb1, which was already a misnomer — it is the first partition
      # of what Debian called sda — so it is renamed here to something that
      # says what it holds rather than where it happened to enumerate.
      "nofail"
      "x-systemd.device-timeout=10s"
    ];
  };

  # ── Platform ───────────────────────────────────────────────
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # First installed on NixOS 26.05. Never bump this to "upgrade" — it selects
  # backwards-compatibility defaults for stateful services.
  system.stateVersion = "26.05";
}
