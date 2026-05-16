{ config, pkgs, lib, ... }:

# Host-specific Home Manager config for this machine.
# This is equivalent to hosts/debian.nix in the standalone HM setup.
# Import it via home-manager.users.jonny.imports in flake.nix.
{
  imports = [
    ../../modules/desktop.nix

    # Uncomment the dev stacks you want on this machine:
    ../../modules/dev/haskell.nix
    # ../../modules/dev/elixir.nix
    # ../../modules/dev/rust.nix
    # ../../modules/dev/ruby.nix
  ];

  home.sessionVariables = {
    WAYLAND_DISPLAY      = "wayland-1";
    NIXOS_OZONE_WL       = "1";
    XDG_SCREENSHOTS_DIR  = "${config.home.homeDirectory}/Pictures/Screenshots";
  };
}
