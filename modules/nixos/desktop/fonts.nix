{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # System-wide fonts: SDDM's login screen and GTK apps need these before
    # any Home Manager profile is activated.
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      intel-one-mono # stands in for Dank Mono when it is not installed
      font-awesome # waybar icons
      noto-fonts
      noto-fonts-color-emoji
    ];
  };
}
