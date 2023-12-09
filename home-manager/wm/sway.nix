{ config, pkgs, lib, ... } :
{
  wayland.windowManager.sway = {
		enable = true;
		config = {
		modifier = "Mod4";
		window = {
		  titlebar = false;
			hideEdgeBorders = "none";
			border = 0;
		};
		input = {
      "*" = {
				xkb_layout = "gb";
			};
		};
		output = {
      "*" = {
				bg = "~/wallpaper.jpg fill";
			};
			"eDP-1" = {
			  mode = "1920x1080@60Hz";
				pos = "0 0";
			};
			"DP-1" = {
				mode = "2560x1440@60Hz";
				pos = "-2560 0";
			};
		};
		terminal = "${pkgs.kitty}/bin/kitty";
		bars = [
			{ command = "${config.programs.waybar.package}/bin/waybar"; }
		];
		fonts = {
		  names = [ "Inter" "NerdFontsSymbolsOnly" ];
			size = 14.0;
		};
		};
	};
}
