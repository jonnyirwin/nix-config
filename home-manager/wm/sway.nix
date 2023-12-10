{ config, pkgs, lib, ... } :
{
  wayland.windowManager.sway = let
		modifier = "Mod4";
	in
	{
		enable = true;
		config = {
		inherit modifier;
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
			"HDMI-A-2" = {
				mode = "2560x1440@60Hz";
				pos = "-2560 0";
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
		  names = [ "Inter" "NerdFontsSymbolsOnly" ];
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
		};
		menu = "${pkgs.wofi}/bin/wofi | xargs swaymsg exec --";
		};
		swaynag = {
			enable = true;
			settings = {
				"<config>" = {
					edge = "bottom";
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
	}

