{ config, pkgs, lib, ... }:

# ============================================================
# Systemd user services
# ============================================================
#
# Home Manager can manage systemd USER services — processes that run
# as your user in the background. These are different from system
# services (which run as root and are managed by NixOS or Debian's
# /etc/systemd/system/).
#
# On Debian with standalone Home Manager:
#   • Home Manager writes service unit files to ~/.config/systemd/user/
#   • They are controlled with `systemctl --user`
#   • They start after login and stop at logout
#   • View status: systemctl --user status syncthing
#   • View logs:   journalctl --user -u syncthing -f
#
# Prerequisites on Debian:
#   systemctl --user enable --now default.target
#   loginctl enable-linger jonny   # keeps services running after logout
#
# ============================================================

{
  # ----------------------------------------------------------
  # GPG agent — key signing and SSH authentication
  # ----------------------------------------------------------
  # gpg-agent caches your GPG passphrase so you don't have to re-enter
  # it for every git commit. With enableSshSupport, it also acts as an
  # SSH agent, so your GPG authentication key can be used for SSH.
  #
  # Your .gitconfig has signingkey = B02BA0E451EA374E — that key must be
  # in your GPG keyring: gpg --list-secret-keys
  services.gpg-agent = {
    enable = true;

    # Cache timeouts: how long before you need to re-enter your passphrase.
    # defaultCacheTtl: time since last use (seconds). 3600 = 1 hour.
    # maxCacheTtl: maximum time regardless of use. 86400 = 24 hours.
    defaultCacheTtl    = 3600;
    maxCacheTtl        = 86400;

    # Use gpg-agent as your SSH agent too. Your GPG auth subkey becomes
    # an SSH key — add its SSH pubkey to GitHub/servers with:
    #   gpg --export-ssh-key YOUR_KEY_ID
    enableSshSupport = true;

    # pinentryPackage determines how the passphrase dialog appears.
    # pinentry-tty: terminal-based (always works, even without GUI)
    # pinentry-gnome3: GTK dialog (nicer on Sway/Wayland)
    # pinentry-qt: Qt dialog
    pinentryPackage = pkgs.pinentry-gnome3;

    # Enable the extra socket for forwarding gpg-agent over SSH.
    # Useful when you want to sign commits on remote servers.
    enableExtraSocket = true;
  };

  # Required companion: install the gpg binary itself.
  programs.gpg = {
    enable = true;
    # settings written to ~/.gnupg/gpg.conf
    settings = {
      # Always show long key IDs (64-bit) rather than short (32-bit).
      # Short IDs are vulnerable to collision attacks.
      keyid-format = "0xlong";
      # Show fingerprints when listing keys.
      with-fingerprint = true;
      # Use gpg-agent for passphrase caching.
      use-agent = true;
    };
  };

  # ----------------------------------------------------------
  # Syncthing — peer-to-peer file synchronisation
  # ----------------------------------------------------------
  # Syncthing syncs directories between your devices without a central
  # server. The web UI runs at http://localhost:8384.
  #
  # First run: open the web UI, add your remote devices by exchanging
  # device IDs (shown in the UI under Actions → Show ID).
  services.syncthing = {
    enable = true;
    # tray.enable = true;  # enable a system tray icon (needs syncthingtray package)
  };

  # ----------------------------------------------------------
  # Mako notification daemon
  # ----------------------------------------------------------
  # Start mako as a user service so notifications work from first login.
  # Config is symlinked from dotfiles in modules/desktop.nix.
  services.mako.enable = true;

  # ----------------------------------------------------------
  # Kanshi display profile manager
  # ----------------------------------------------------------
  # kanshi automatically applies display configurations (resolution,
  # arrangement) based on which monitors are connected. Like autorandr
  # but for Wayland. Create profiles in ~/.config/kanshi/config.
  services.kanshi = {
    enable = true;
    # profiles are in ~/.config/kanshi/config — create per-monitor profiles:
    # profile home {
    #   output "HDMI-A-1" enable mode 2560x1440@144Hz position 0,0
    #   output eDP-1 enable mode 1920x1080@60Hz position 2560,0
    # }
  };

  # ----------------------------------------------------------
  # Gammastep — screen colour temperature (blue light reduction)
  # ----------------------------------------------------------
  # Gradually shifts screen colour temperature from neutral (daytime)
  # to warm (night). Like f.lux or redshift but for Wayland.
  services.gammastep = {
    enable    = true;
    provider  = "manual";
    latitude   = 51.5;   # your latitude (London-ish; adjust for your city)
    longitude  = -0.1;   # your longitude
    temperature = {
      day   = 6500;    # Kelvin — neutral white for daytime
      night = 3500;    # Kelvin — warm orange for evening
    };
  };

  # ----------------------------------------------------------
  # Network Manager Applet — system tray Wi-Fi manager
  # ----------------------------------------------------------
  # Shows a Wi-Fi icon in the system tray (if your bar has a tray area).
  # Your waybar config may handle network display directly — enable this
  # only if you want the GTK applet too.
  # services.network-manager-applet.enable = true;
}
