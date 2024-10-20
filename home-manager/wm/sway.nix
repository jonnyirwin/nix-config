{
  config,
  pkgs,
  lib,
  nix-colors,
  ...
}: {
  imports = [
    ./swaylock.nix
    ./waybar.nix
    ./rofi.nix
    ./mako.nix
  ];

  config = lib.mkIf (config.environment.desktop == "sway") {
    wayland.windowManager.sway = let
      modifier = "Mod4";
      inherit (nix-colors.lib-contrib {inherit pkgs;}) nixWallpaperFromScheme;
      bg = nixWallpaperFromScheme {
        scheme = config.colorScheme;
        width = 1920;
        height = 1080;
        logoScale = 5.0;
      };
    in {
      enable = true;
      extraConfig = ''
        set $gnome-schema org.gnome.desktop.interface

        exec_always {
            gsettings set $gnome-schema gtk-theme '${config.gtk.theme.name}'
            gsettings set $gnome-schema icon-theme '${config.gtk.iconTheme.name}'
            gsettings set $gnome-schema font-name 'Inter 12'
        }
      '';
      config = {
        inherit modifier;
        window = {
          titlebar = false;
          hideEdgeBorders = "none";
          border = 0;
        };
				defaultWorkspace = "1";
        input = {
          "*" = {
            xkb_layout = "gb";
          };
        };
        output = {
          "*" = {
            bg = "${bg} fill";
          };
          "eDP-1" = {
            mode = "1920x1080@60Hz";
            pos = "0 0";
          };
          "DP-1" = {
            mode = "2560x1440@60Hz";
            pos = "1920 0";
          };
          "HDMI-A-2" = {
            mode = "2560x1440@60Hz";
            pos = "1920 0";
          };
        };
        terminal = "${pkgs.kitty}/bin/kitty";
        bars = [
          {
            command = "${config.programs.waybar.package}/bin/waybar";
            position = "bottom";
          }
        ];
        fonts = {
          names = ["Inter" "NerdFontsSymbolsOnly"];
          size = 14.0;
        };
        gaps = {
          bottom = 5;
          horizontal = 5;
          inner = 5;
          left = 5;
          outer = 5;
          right = 5;
          top = 5;
          vertical = 5;
          smartGaps = true;
        };
        keybindings = lib.mkOptionDefault {
          "${modifier}+Shift+e" = "exec swaynag -t warning -m 'What do you want to do?' -B 'Power off' 'systemctl poweroff' -B 'Reboot' 'systemctl reboot' -B 'Logout' 'swaymsg exit'";
          "${modifier}+Shift+l" = "exec swaylock -f -c 000000";
					"XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
					"XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
					"${modifier}+p" = "exec grimshot save active";
					"${modifier}+Shift+p" = "exec grimshot save area";
					"${modifier}+Ctrl+p" = "exec grimshot save window";				        };
        menu = "${pkgs.rofi}/bin/rofi -show drun -monitor -1";
      };
      swaynag = {
        enable = true;
        settings = {
          "<config>" = {
            edge = "top";
            font = "Inter 12";
          };

          green = {
            edge = "top";
            background = "00AA00";
            text = "FFFFFF";
            button-background = "00CC00";
            message-padding = 10;
          };
        };
      };
      wrapperFeatures = {
        gtk = true;
      };
    };
  };
}
