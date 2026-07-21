{ config, pkgs, lib, ... }:

# NixOS-level desktop plumbing.
# Handles the session, audio, portals, and GPU.
# Sway/Waybar *configuration* lives in Home Manager (modules/desktop.nix).
{
  # ── Sway session ───────────────────────────────────────────
  # Installs sway with correct capabilities and registers the Wayland session.
  programs.sway = {
    enable         = true;
    wrapperFeatures.gtk = true;   # fixes GTK apps not picking up theme
    # Default extraPackages includes foot and dmenu — use kitty instead.
    extraPackages  = with pkgs; [ swaylock swayidle kitty ];
  };

  # ── Display manager ────────────────────────────────────────
  # greetd is lightweight and Wayland-native.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
      user    = "greeter";
    };
  };

  # ── XDG portals ────────────────────────────────────────────
  # Required for screen sharing, file picker, and app sandboxing under Wayland.
  xdg.portal = {
    enable       = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr  # wlroots portal (sway/river/etc.)
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # ── Audio (Pipewire) ───────────────────────────────────────
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };
  # Pipewire replaces PulseAudio; disable the latter explicitly.
  services.pulseaudio.enable = false;
  security.rtkit.enable     = true;   # lets Pipewire request realtime priority

  # ── GPU ────────────────────────────────────────────────────
  hardware.graphics.enable      = true;
  hardware.graphics.enable32Bit = true;  # needed for Steam / 32-bit GL apps

  # ── Bluetooth ──────────────────────────────────────────────
  hardware.bluetooth = {
    enable      = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ── Fonts (system-wide) ────────────────────────────────────
  # Login screen and GTK apps need fonts before HM activates.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  # ── Polkit ─────────────────────────────────────────────────
  # Required for GUI apps that need privilege escalation (e.g. gparted).
  security.polkit.enable = true;

  # ── 1Password (desktop app + CLI) ──────────────────────────
  # Installed at the system level because the GUI needs a polkit policy
  # and a setuid helper, and this module installs the browser
  # native-messaging manifests that let the Firefox extension unlock via
  # the desktop app (the extension itself is force-installed in the HM
  # modules/desktop.nix Firefox policy).
  programs._1password.enable = true;      # the `op` CLI
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "jonny" ];     # allow jonny to unlock via system auth
  };
}
