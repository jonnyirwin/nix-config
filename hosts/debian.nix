{ config, pkgs, lib, ... }:

# ============================================================
# Host-specific configuration: debian (primary workstation)
# ============================================================
#
# Multi-host pattern explained
# ────────────────────────────
# home.nix contains everything that's UNIVERSAL — the same on every
# machine you own (git identity, shell config, neovim, core CLI tools).
#
# THIS file contains everything SPECIFIC to this machine:
#   - The desktop environment (Sway, Waybar, etc.) — headless servers don't have these
#   - The full dev stack — a dedicated build server might only need one language
#   - Machine-specific hardware settings, display configs, etc.
#
# In flake.nix, each host is a homeManagerConfiguration with:
#   modules = [ ./home.nix ./hosts/THIS_FILE.nix ]
#
# To add a second machine (e.g. a work laptop):
#   1. Copy this file to hosts/work-laptop.nix
#   2. Adjust which dev stacks and desktop modules it imports
#   3. Add to flake.nix:
#        homeConfigurations."jonny@work-laptop" = home-manager.lib.homeManagerConfiguration {
#          inherit pkgs;
#          extraSpecialArgs = { ... };
#          modules = [ ./home.nix ./hosts/work-laptop.nix ];
#        };
#   4. Switch: home-manager switch --flake ~/git/nix#jonny@work-laptop
# ============================================================

{
  imports = [
    # ---- GUI desktop environment ----
    # Remove this block for headless machines (servers, CI nodes).
    ../modules/desktop.nix   # Sway, Waybar, Rofi, Mako, fonts

    # ---- Development stacks ----
    # Comment out stacks you don't use on this machine to avoid
    # installing tools you never need (keeps activation fast).
    ../modules/dev/haskell.nix
    ../modules/dev/elixir.nix
    ../modules/dev/rust.nix
    ../modules/dev/ruby.nix
  ];

  # ----------------------------------------------------------
  # Machine-specific session variables
  # ----------------------------------------------------------
  home.sessionVariables = {
    # Wayland display socket — used by wl-clipboard, wlr-randr, etc.
    # "wayland-1" is the default; change if your compositor uses a different socket.
    WAYLAND_DISPLAY = "wayland-1";

    # Hint Electron/Chromium apps to use the Wayland backend.
    # Already set in shell.nix but repeated here for non-interactive sessions.
    NIXOS_OZONE_WL = "1";

    # XDG screenshot directory — used by your Sway screenshot scripts.
    XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
  };

  # ----------------------------------------------------------
  # Machine-specific packages
  # ----------------------------------------------------------
  home.packages = with pkgs; [
    # GUI applications that only make sense on a desktop machine:
    # obsidian        # note-taking — uncomment if you use it here
    # discord         # chat
    # spotify         # music
    # gimp            # image editor
    # inkscape        # vector graphics

    # Hardware-specific tools:
    # qmk             # keyboard firmware flashing
  ];
}
