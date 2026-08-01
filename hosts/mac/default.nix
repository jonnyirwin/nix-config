{ inputs, lib, ... }:

# ============================================================
# Host: mac — Apple MacBookPro8,3 (17", 2011), Intel i7-2720QM (Sandy Bridge)
# ============================================================
# 16 GB RAM, one 256 GB SATA SSD, 64-bit UEFI, dual GPU (Intel HD 3000 +
# AMD Radeon HD 6750M). Encrypted (LUKS) root, hibernates to an encrypted swap
# LV.
#
# This machine is old and particular, so the guiding rule here is to reproduce
# the arrangement that already works under EndeavourOS rather than to improve
# on it. Where something looks odd below, it is because the hardware is.
{
  imports = [
    # Disks. ./disks declares the partition layout, and disko derives
    # fileSystems, swapDevices and the LUKS unlock from it.
    #
    # WARNING: these mounts do not exist until ./disks has been applied.
    inputs.disko.nixosModules.disko
    ./disks

    # Hardware detected rather than guessed. Regenerate after a hardware
    # change with:
    #   sudo nix run nixpkgs#nixos-facter -- -o hosts/mac/facter.json
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }

    # The 8-1 profile, not an 8-3 one — upstream has no 8-3. The difference
    # between the two models is the discrete GPU, which 8,1 lacks and which is
    # handled by hand below; everything else 8-1 provides is correct here:
    # mbpfan (the fans are unusable without it), Sandy Bridge tuning,
    # common/pc/laptop, common/pc/ssd, and networking.enableB43Firmware.
    #
    # That last one matters. The AirPort card is a BCM4331 driven by the
    # in-tree b43, which needs extracted Broadcom firmware to associate at all
    # — without it the machine has no wireless. It is unfree, which is fine:
    # modules/nixos/core/nix.nix sets allowUnfree. Note the PHY is 2.4 GHz
    # only ("5 GHz band is unsupported on this PHY"), so this machine is the
    # slowest and least reliable one on the network. That is the hardware, not
    # a misconfiguration.
    inputs.nixos-hardware.nixosModules.apple-macbook-pro-8-1
  ];

  # The Apple profile turns this on whenever allowUnfree is set, and it is
  # wrong for this model. facetimehd drives the PCIe camera Apple shipped from
  # 2013 onwards; the camera in this machine is a USB device (05ac:8509), so
  # the driver binds nothing and the only effect is dragging a firmware
  # derivation built from Apple driver blobs into every rebuild.
  hardware.facetimehd.enable = false;

  jonny = {
    desktop = {
      enable = true;
      compositor = "sway";

      # No `greeter` block and no per-output config: the internal panel is in
      # its native orientation, and sway picks its mode on its own. Note the
      # panel hangs off the Radeon rather than the Intel GPU — see the GPU
      # note below.

      # Off, as on bearnagh. A 2011 GPU is not what this machine is for, and
      # the printer/scanner live on optiplex's LAN.
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
    # the three steps in .sops.yaml, create secrets/mac.yaml, then uncomment.
    # secrets.enable = true;
  };

  boot = {
    # ── GPU ──────────────────────────────────────────────────
    # This is a dual-GPU MacBook Pro, and under EFI the *discrete* Radeon
    # drives the internal panel — vga_switcheroo reports
    # `0:DIS:+:Pwr` with the Intel IGD powered but idle. So the discrete card
    # cannot simply be switched off; the display goes with it.
    #
    # `radeon.runpm=0` disables runtime power management for that card. It is
    # what the working EndeavourOS install boots with, and it is the standard
    # fix for this generation of MacBook Pro, where letting the kernel power
    # the Radeon down and back up hangs the machine.
    #
    # Deliberately NOT attempting to force integrated-only graphics. It is
    # possible (the gpu-switch EFI-variable trick), and on a model whose
    # discrete GPU is famous for failing it is tempting, but it is a change to
    # firmware state rather than to this config, it can leave the machine
    # without display output, and it is not what is running today.
    kernelParams = [ "radeon.runpm=0" ];

    # ── Keyboard ─────────────────────────────────────────────
    # Apple keyboards expose F-keys and media keys on the same row, and which
    # one you get without holding Fn is a module parameter. 3 is what the
    # machine runs today; it is set explicitly because the kernel default for
    # this has changed over time and a silent flip is an annoying thing to
    # debug later.
    extraModprobeConfig = ''
      options hid_apple fnmode=3
    '';

    # ── Hibernation ──────────────────────────────────────────
    # The machine hibernates today (`resume=` is on its current kernel command
    # line), so it keeps a real swap device rather than bearnagh's zram. The
    # LV lives inside the LUKS container, so unlike the old layout the
    # hibernation image — a verbatim copy of RAM — is encrypted at rest.
    resumeDevice = "/dev/pool/swap";

    # ── Boot ─────────────────────────────────────────────────
    loader.systemd-boot = {
      enable = true;

      # Each generation parks a kernel and initrd on a 1 GB ESP.
      configurationLimit = 20;
    };

    # False, unlike the other two hosts. Apple's EFI implementation is not the
    # firmware the rest of the fleet runs, and writing EFI variables on these
    # machines has a long history of going badly. It is also unnecessary here:
    # the ESP already boots through the removable fallback path
    # (EFI/BOOT/BOOTX64.EFI), which is how Macs find a non-macOS loader, and
    # bootctl still installs that copy with variable writes disabled.
    loader.efi.canTouchEfiVariables = false;
  };

  # ── Platform ───────────────────────────────────────────────
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # First installed on NixOS 26.05. Never bump this to "upgrade" — it selects
  # backwards-compatibility defaults for stateful services.
  system.stateVersion = "26.05";
}
