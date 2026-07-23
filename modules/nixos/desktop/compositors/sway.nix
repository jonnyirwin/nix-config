{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.desktop;
in
{
  # System-level Sway: correct capabilities and a registered Wayland session.
  # The *configuration* (keybindings, outputs, colours) is Home Manager's job —
  # see modules/home/desktop/sway.nix.
  config = lib.mkIf (cfg.enable && cfg.compositor == "sway") {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # GTK apps otherwise ignore the theme

      # The default extraPackages pulls in foot and dmenu; we use kitty and rofi.
      extraPackages = with pkgs; [ swaylock swayidle kitty ];
    };
  };
}
