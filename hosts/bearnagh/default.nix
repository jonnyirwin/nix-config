{ inputs, lib, ... }:

# ============================================================
# Host: bearnagh — Lenovo ThinkPad X270, Intel i5-6200U (Skylake)
# ============================================================
# 16 GB RAM, one 240 GB SATA SSD, 1920x1080 eDP panel. Encrypted (LUKS) root;
# UEFI / systemd-boot. Everything here is either a hardware fact or a
# deliberate per-host choice; shared behaviour lives in modules/nixos.
{
  imports = [
    # Disks. ./disks declares the partition layout, and disko derives
    # fileSystems, swapDevices and the LUKS unlock from it. As on optiplex
    # there is no generated hardware.nix — a second source of truth for mounts
    # is how you end up with a config that formats one disk and boots another.
    #
    # WARNING: these mounts do not exist until ./disks has been applied.
    # Building this config is safe; it describes a machine that does not exist
    # yet until the install runs.
    inputs.disko.nixosModules.disko
    ./disks

    # Hardware detected rather than guessed. Regenerate after a hardware
    # change with:
    #   sudo nix run nixpkgs#nixos-facter -- -o hosts/bearnagh/facter.json
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }

    # One import covers what optiplex spells out as three. The x270 profile
    # already pulls in common-cpu-intel, common-pc and common-pc-ssd via
    # common/pc/laptop, and adds what is specific to this machine: the
    # TrackPoint (with wheel emulation), TLP, and `i915.enable_psr=0` — Panel
    # Self Refresh causes random freezes on this panel.
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x270
  ];

  jonny = {
    desktop = {
      enable = true;
      compositor = "sway";

      # No `greeter` block. optiplex needs one only because its panel is
      # mounted portrait and SDDM has to be told; the built-in display here is
      # eDP-1 in its native orientation, which is already what SDDM assumes.

      # Deliberately off, unlike optiplex:
      #   steam    — HD 520 integrated graphics is not what this machine is for
      #   printing — the declared ENVY queue is optiplex's LAN, not something
      #              a laptop should carry around
      #   scanning — same
      # Turn any of them on here if that stops being true.
    };

    # Same theme as optiplex so the two machines look like one system. Change
    # either line to re-theme everything: SDDM reads it directly, and the Home
    # Manager side defaults from it, so the greeter and the session cannot
    # drift apart. Schemes: catppuccin-{latte,frappe,macchiato,mocha},
    # gruvbox-dark, nord — see lib/schemes/.
    theme = {
      scheme = "catppuccin-mocha";
      accent = "purple";
    };

    services.openssh.enable = true;
    services.tailscale.enable = true;
    security.passwordlessSudo = true;

    # Stays off until the machine has booted once. The sops identity is this
    # host's SSH host key, which does not exist until NixOS has generated it —
    # enabling this on the first install gives you an activation failure, not a
    # useful error. After first boot, follow the three steps in .sops.yaml,
    # create secrets/bearnagh.yaml, then uncomment this.
    # secrets.enable = true;
  };

  # ── Swap ───────────────────────────────────────────────────
  # Compressed RAM rather than a swap LV, which is what Fedora ran on this
  # machine and what a 2013-era SandForce SSD would rather not be doing. It
  # also keeps the whole 222 GB available on a disk that has none to spare.
  #
  # The cost is hibernation: suspend-to-disk needs a real swap device at least
  # the size of RAM. If you want it, add a 16 GB `swap` LV to ./disks
  # (hosts/optiplex/disks/nvme.nix has one to copy) and set
  # `boot.resumeDevice = "/dev/pool/swap"`.
  zramSwap.enable = true;

  boot = {
    # ── Boot ─────────────────────────────────────────────────
    loader.systemd-boot = {
      enable = true;

      # Each generation parks a kernel and initrd on the ESP. optiplex leaves
      # this unbounded and gets away with it; on a 1 GB ESP that a laptop
      # rebuilds against often, unbounded means a switch that eventually fails
      # at the bootloader step with the disk full.
      configurationLimit = 20;
    };
    loader.efi.canTouchEfiVariables = true;

    # ── Disk encryption ──────────────────────────────────────
    # Nothing to declare. disko emits the LUKS unlock for `cryptroot` from
    # ./disks/default.nix.
  };

  # ── Platform ───────────────────────────────────────────────
  # lib/mkHost.nix does not pass `system` to nixosSystem on purpose, so it has
  # to come from the host.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # First installed on NixOS 26.05. Never bump this to "upgrade" — it selects
  # backwards-compatibility defaults for stateful services.
  system.stateVersion = "26.05";
}
