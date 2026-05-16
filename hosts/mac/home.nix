{ config, pkgs, lib, ... }:

# ============================================================
# Home Manager config: mac (2011 MacBook Pro)
# ============================================================
# Machine-specific user environment. Universal config lives in home.nix.
{
  imports = [
    ../../modules/desktop.nix

    # Dev stacks — comment out what you don't need on this machine.
    ../../modules/dev/haskell.nix
    ../../modules/dev/elixir.nix
    ../../modules/dev/rust.nix
    ../../modules/dev/ruby.nix
  ];

  home.sessionVariables = {
    WAYLAND_DISPLAY     = "wayland-1";
    NIXOS_OZONE_WL      = "1";
    XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
  };

  # Mac-specific packages (user level).
  home.packages = with pkgs; [
    # intel-gpu-tools   # uncomment for GPU debugging (intel_gpu_top etc.)
  ];
}
