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

      # No greeter block: the panel is landscape now, so there is no rotation
      # to keep in step with hosts/optiplex/home.nix. Leaving greeter.output
      # null is what keeps SDDM on its stock weston command and keeps the
      # `video=DP-1:rotate=…` console parameter out of the kernel command line
      # (modules/nixos/desktop/plymouth.nix), rather than setting each of them
      # to a "normal" that means the same as absent.

      steam.enable = true;
      printing.enable = true;
      scanning.enable = true;
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

    services = {
      openssh = {
        enable = true;
        # Tailnet plus the home LAN. IPv6 by link-local only: LAN peers' global
        # addresses share the ISP's rotating prefix, so there's no stable range.
        lanSubnets = [ "192.168.1.0/24" "fe80::/10" ];
      };
      tailscale.enable = true;

      # Local LLMs, CPU only. Sized for 32 GB of DDR4-2666: a ~15 GB 3-bit MoE
      # leaves room for the desktop and a browser without touching swap. The
      # weights go on /mnt/data — the NVMe's large volume — rather than root,
      # which the Nix store also has to fit in.
      ollama = {
        enable = true;
        modelsDir = "/mnt/data/ollama";
        models = [
          "hf.co/unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q3_K_S"
          "gemma4:12b-it-qat"
        ];
      };
    };

    secrets.enable = true;
    security.passwordlessSudo = true;
  };

  # ── Firmware ───────────────────────────────────────────────
  # BIOS updates without a vendor USB stick. This box boots UEFI with a 1G ESP,
  # so `fwupdmgr update` can stage a capsule there and let it flash on the next
  # reboot. LVFS does carry this model — 1.34.1 installed, 1.41.0 available.
  # Added while chasing the fan-at-full-speed fault, which turned out to be a
  # spinning respawn loop rather than firmware; kept for the next BIOS update.
  services.fwupd.enable = true;

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
