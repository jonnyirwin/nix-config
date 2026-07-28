{ inputs, lib, ... }:

# ============================================================
# Host: optiplex — Dell OptiPlex 3000, Intel i3-12100T (Alder Lake)
# ============================================================
# Encrypted (LUKS) root + encrypted swap; UEFI / systemd-boot.
# Everything here is either a hardware fact or a deliberate per-host choice;
# shared behaviour lives in modules/nixos.
{
  imports = with inputs.nixos-hardware.nixosModules; [
    # Disks. ./disks declares the partition layout, and disko derives
    # fileSystems, swapDevices and the LUKS unlock from it — so this is both
    # the thing that formats the machine and the thing that tells the running
    # system what to mount. There is deliberately no generated hardware.nix
    # any more: it described the *old* single-SSD layout, and keeping a second
    # source of truth for mounts is how you end up with a config that formats
    # one disk and boots another.
    #
    # WARNING: these mounts do not exist until ./disks has been applied. See
    # docs/disk-migration.md — building this config is safe, switching to it
    # on the pre-migration layout produces a system that cannot boot.
    inputs.disko.nixosModules.disko
    ./disks

    # Hardware detected rather than guessed, and now the only source of the
    # kernel modules and firmware facts hardware.nix used to carry. Regenerate
    # after a hardware change with:
    #   sudo nix run nixpkgs#nixos-facter -- -o hosts/optiplex/facter.json
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

      # The panel is mounted portrait. SDDM runs before Home Manager, so the
      # greeter rotation is set here to match the session's transform in
      # hosts/optiplex/home.nix (jonny.desktop.outputs."DP-1".transform).
      greeter = {
        output = "DP-1";
        transform = "90";
      };

      steam.enable = true;
    };

    # The host's one theme declaration. Change either line to re-theme
    # everything: SDDM reads it directly, and the Home Manager side defaults
    # from it, so the greeter and the session cannot drift apart. Schemes:
    # catppuccin-{latte,frappe,macchiato,mocha}, gruvbox-dark, nord — see
    # lib/schemes/. The accent is named by hue, so it keeps its meaning across
    # schemes: "purple" is Catppuccin's mauve, Gruvbox's bright purple, Nord's
    # nord15.
    theme = {
      scheme = "catppuccin-mocha";
      accent = "purple";
    };

    services.openssh.enable = true;
    services.tailscale.enable = true;
    secrets.enable = true;
    security.passwordlessSudo = true;
  };

  boot = {
    # ── Boot ─────────────────────────────────────────────────
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    # ── Disk encryption ──────────────────────────────────────
    # Nothing to declare. disko emits the LUKS unlock for `cryptroot` from
    # ./disks/nvme.nix, and swap is an LV inside that container rather than the
    # second LUKS device the old layout needed — one passphrase at boot, not
    # two.
  };

  # ── Platform ───────────────────────────────────────────────
  # Was in the generated hardware.nix, which is gone. lib/mkHost.nix does not
  # pass `system` to nixosSystem on purpose, so it has to come from the host.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # First installed on NixOS 26.05. Never bump this to "upgrade" — it selects
  # backwards-compatibility defaults for stateful services.
  system.stateVersion = "26.05";
}
