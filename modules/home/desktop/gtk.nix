{ config, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
  theme = config.jonny.theme;

  capitalise = s: "${lib.toUpper (builtins.substring 0 1 s)}${builtins.substring 1 (-1) s}";

  # catppuccin-gtk builds share/themes/catppuccin-<flavor>-<accent>-standard,
  # catppuccin-cursors is attribute-named <flavor><Accent> and installs
  # share/icons/catppuccin-<flavor>-<accent>-cursors. The previous config named
  # "Catppuccin-Mocha-Standard-Mauve-Dark", which matches nothing that is
  # actually installed — GTK theming has been silently falling back to Adwaita.
  themeName = "catppuccin-${theme.flavor}-${theme.accent}-standard";
  cursorName = "catppuccin-${theme.flavor}-${theme.accent}-cursors";
in
{
  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;

      theme = {
        name = themeName;
        package = pkgs.catppuccin-gtk.override {
          accents = [ theme.accent ];
          variant = theme.flavor;
        };
      };

      # Silences the HM 26.05 migration warning while keeping the previous
      # behaviour of GTK4 mirroring the GTK3 theme.
      gtk4.theme = config.gtk.theme;

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      cursorTheme = {
        name = cursorName;
        package = pkgs.catppuccin-cursors."${theme.flavor}${capitalise theme.accent}";
        size = 24;
      };
    };

    # Match the cursor in Wayland-native clients too.
    home.pointerCursor = {
      name = cursorName;
      package = pkgs.catppuccin-cursors."${theme.flavor}${capitalise theme.accent}";
      size = 24;
      gtk.enable = true;
    };
  };
}
