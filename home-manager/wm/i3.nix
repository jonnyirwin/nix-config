{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  modifier = "Mod4";
in {
  config = lib.mkIf (config.environment.desktop
    == "i3") {
    xsession.enable = true;
    xsession.windowManager.i3 = {
      enable = true;
      package = pkgs-unstable.i3-gaps;
      config = {
        inherit modifier;
        window = {
          titlebar = false;
          hideEdgeBorders = "none";
          border = 0;
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
        };
        menu = "${pkgs.rofi}/bin/rofi -show drun -modi drun,run -lines 1";
      };
    };
  };
}
