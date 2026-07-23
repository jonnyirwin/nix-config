{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Required for screen sharing, the file picker, and app sandboxing on Wayland.
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-wlr # wlroots compositors (sway)
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };
}
