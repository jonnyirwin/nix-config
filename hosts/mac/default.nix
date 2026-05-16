{ config, pkgs, lib, ... }:

# ============================================================
# Host: mac — 2011 MacBook Pro (Intel, BCM4331 Wi-Fi)
# ============================================================
{
  imports = [
    ./hardware.nix

    # Laptop power management, lid switch, touchpad, upower.
    ../../nixos-modules/hardware/laptop.nix
  ];

  networking.hostName = "mac";

  # ── Boot ───────────────────────────────────────────────────
  # Apple's older EFI firmware does not support standard EFI variable writes.
  # canTouchEfiVariables = false prevents Linux from attempting them, which
  # would otherwise corrupt the boot entry on some Macs.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # ── Wi-Fi: Broadcom BCM4331 ────────────────────────────────
  # The BCM4331 needs the proprietary broadcom_sta driver (wl module).
  # b43/bcma/ssb are open-source drivers that probe the same hardware
  # and must be blacklisted so wl can claim the device.
  #
  # broadcom-sta is marked insecure (CVE-2019-9501/9502 — unmaintained
  # upstream). It is the only driver that works for BCM4331 on Linux.
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.18.31"
  ];

  boot.kernelModules       = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [ "b43" "bcma" "ssb" "brcmsmac" ];

  # ── GPU: Intel HD 3000 + AMD Radeon discrete ───────────────
  # The 2011 MBP has a discrete AMD Radeon GPU notorious for hardware
  # failures (Apple ran a repair programme for it). Under Linux, the
  # Radeon DPM (dynamic power management) triggers GPU panics/hangs.
  # radeon.dpm=0 disables it; the Intel GPU handles everything safely.
  #
  # If you want to try using the discrete GPU, remove radeon.dpm=0 and
  # see /sys/kernel/debug/vgaswitcheroo/switch for runtime switching.
  boot.kernelParams = [
    "radeon.dpm=0"          # prevents Radeon DPM crashes on 2011 MBP
    "acpi_backlight=vendor" # use Apple's vendor backlight driver
    "hid_apple.fnmode=2"    # F1–F12 behave as function keys; Fn for media
  ];

  # ── Firmware ───────────────────────────────────────────────
  # Includes Intel GPU microcode and other redistributable blobs.
  hardware.enableRedistributableFirmware = true;

  # ── Fan control ────────────────────────────────────────────
  # mbpfan reads Apple SMC temperature sensors and controls fan speed.
  # Without it, Linux's generic fan control under-spins and the machine
  # runs hot (Apple's SMC doesn't respond to ACPI fan control).
  services.mbpfan = {
    enable = true;
    settings.general = {
      low_temp  = 63;
      high_temp = 66;
      max_temp  = 86;
    };
  };

  # ── Machine-specific system packages ───────────────────────
  environment.systemPackages = [ ];
}
