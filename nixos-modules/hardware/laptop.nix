{ config, pkgs, lib, ... }:

# Laptop-specific power management and hardware tweaks.
# Import this in hosts/<name>/default.nix for portable machines.
{
  # ── Power management ───────────────────────────────────────
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor    = "powersave";
        turbo       = "never";
      };
      charger = {
        governor    = "performance";
        turbo       = "auto";
      };
    };
  };

  # Broader power saving (backlight, USB autosuspend, etc.).
  powerManagement.enable = true;

  # ── Lid / power button behaviour ───────────────────────────
  services.logind = {
    lidSwitch            = "suspend";
    lidSwitchExternalPower = "lock";
    extraConfig          = "HandlePowerKey=suspend";
  };

  # ── Battery info ───────────────────────────────────────────
  services.upower.enable = true;

  # ── Touchpad ───────────────────────────────────────────────
  # libinput is enabled by default on NixOS; this just sets sane defaults.
  # Fine-tune per-machine in hosts/<name>/default.nix if needed.
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping          = true;
      disableWhileTyping = true;
    };
  };
}
