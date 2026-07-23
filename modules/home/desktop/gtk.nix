{ config, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
  theme = config.jonny.theme;
  myLib = import ../../../lib { inherit lib; };

  capitalise = s: "${lib.toUpper (builtins.substring 0 1 s)}${builtins.substring 1 (-1) s}";

  # catppuccin-gtk only produces Catppuccin, so GTK follows the scheme when it
  # is one and falls back to Adwaita otherwise. GTK is the one surface we
  # cannot render from raw palette values.
  flavor = myLib.catppuccinFlavors.${theme.scheme} or null;
  # catppuccin-gtk and catppuccin-cursors both use Catppuccin's own accent
  # names, so translate out of the generic hue vocabulary here.
  ctpAccent = myLib.catppuccinAccents.${theme.accent};
  isCatppuccin = flavor != null;

  # catppuccin-gtk builds share/themes/catppuccin-<flavor>-<accent>-standard,
  # catppuccin-cursors is attribute-named <flavor><Accent> and installs
  # share/icons/catppuccin-<flavor>-<accent>-cursors. The previous config named
  # "Catppuccin-Mocha-Standard-Mauve-Dark", which matches nothing that is
  # actually installed — GTK theming had been silently falling back to Adwaita.
  themeName = "catppuccin-${flavor}-${ctpAccent}-standard";
  cursorName = "catppuccin-${flavor}-${ctpAccent}-cursors";
  cursorPackage = pkgs.catppuccin-cursors."${flavor}${capitalise ctpAccent}";
in
{
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      gtk = {
        enable = true;

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      # Qt apps (OpenSCAD and friends) follow via qt5ct; the
      # QT_QPA_PLATFORMTHEME export lives in modules/home/shell/fish.nix.
      home.packages = [ pkgs.libsForQt5.qt5ct ];
    }

    (lib.mkIf isCatppuccin {
      gtk = {
        theme = {
          name = themeName;
          package = pkgs.catppuccin-gtk.override {
            accents = [ ctpAccent ];
            variant = flavor;
          };
        };

        # Silences the HM 26.05 migration warning while keeping the previous
        # behaviour of GTK4 mirroring the GTK3 theme.
        gtk4.theme = config.gtk.theme;

        cursorTheme = {
          name = cursorName;
          package = cursorPackage;
          size = 24;
        };
      };

      # Match the cursor in Wayland-native clients too.
      home.pointerCursor = {
        enable = true;
        name = cursorName;
        package = cursorPackage;
        size = 24;
        gtk.enable = true;
      };
    })

    (lib.mkIf (!isCatppuccin) {
      gtk.theme.name = "Adwaita-dark";
      gtk.gtk4.theme.name = "Adwaita-dark";
    })
  ]);
}
