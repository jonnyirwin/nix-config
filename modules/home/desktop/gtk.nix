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

  # Naming a dark GTK theme is not the same as telling the desktop it *is*
  # dark: the theme name is a string nothing interprets. Applications that ask
  # "is the system in dark mode?" — Firefox, Chromium, Electron, anything using
  # prefers-color-scheme — read org.freedesktop.appearance from the portal, and
  # xdg-desktop-portal-gtk answers it from this GSettings key. With the key
  # unset the portal reports 0 ("no preference"), which those applications treat
  # as light, so a fully dark session still rendered light UI everywhere.
  #
  # gtk-application-prefer-dark-theme covers the other half: GTK3 apps read the
  # setting directly rather than going through the portal.
  isDark = theme.palette.polarity == "dark";
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

        # GTK had no font of its own here, so it sat at whatever Adwaita
        # defaults to and text scaling stopped at the edge of the Wayland
        # shell. Naming the UI font means jonny.theme.fonts.scale reaches file
        # dialogs, Thunar and every other GTK surface in the same move as the
        # bar and the terminal. The package is null: the family is installed
        # by theme/default.nix already, and naming it twice would install it
        # twice.
        font = {
          name = theme.fonts.ui.family;
          size = theme.fonts.ui.size;
        };

        gtk3.extraConfig.gtk-application-prefer-dark-theme = isDark;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = isDark;
      };

      dconf.settings."org/gnome/desktop/interface".color-scheme =
        if isDark then "prefer-dark" else "prefer-light";
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

    (lib.mkIf (!isCatppuccin) (
      let adwaita = if isDark then "Adwaita-dark" else "Adwaita"; in
      {
        gtk.theme.name = adwaita;
        gtk.gtk4.theme.name = adwaita;
      }
    ))
  ]);
}
