{ config, pkgs, lib, ... }:

# ============================================================
# Home Manager config: optiplex (Dell OptiPlex desktop)
# ============================================================
# Machine-specific user environment. Universal config lives in home.nix.
{
  imports = [
    ../../modules/desktop.nix   # Sway, Waybar, Rofi, Mako + dotfile symlinks

    # Dev stacks — uncomment the ones you want on this machine.
    # Left off for a lean first build; each pulls a full toolchain.
    # ../../modules/dev/haskell.nix
    # ../../modules/dev/elixir.nix
    # ../../modules/dev/rust.nix
    # ../../modules/dev/ruby.nix
  ];

  home.sessionVariables = {
    WAYLAND_DISPLAY     = "wayland-1";
    NIXOS_OZONE_WL      = "1";
    XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
  };

  # Desktop-specific packages (user level).
  home.packages = with pkgs; [ ];
}
