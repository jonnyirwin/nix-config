{ config, lib, pkgs, ... }:
{
	programs.kitty = {
		enable = true;
		font = {
			name = "Intel One Mono";
			package = pkgs.intel-one-mono;
     	size = 16.0;
		};

		shellIntegration = {
			enableFishIntegration = true;
		};
		settings = {
			background_opacity = "0.9";
			symbol_map = "U+e000-U+e00a,U+ea60-U+ebeb,U+e0a0-U+e0c8,U+e0ca,U+e0cc-U+e0d4,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b1,U+e700-U+e7c5,U+f000-U+f2e0,U+f300-f372,U+f400-U+f532,U+f0001-U+f1af0 Symbols Nerd Font Mono";
		};
		extraConfig = ''
		# nix-colors - kitty color config
		background #${config.colorScheme.palette.base00}
		foreground #${config.colorScheme.palette.base05}
		selection_background #${config.colorScheme.palette.base05}
		selection_foreground #${config.colorScheme.palette.base00}
		url_color #${config.colorScheme.palette.base04}
		cursor #${config.colorScheme.palette.base05}
		active_border_color #${config.colorScheme.palette.base03}
		inactive_border_color #${config.colorScheme.palette.base01}
		active_tab_background #${config.colorScheme.palette.base00}
		active_tab_foreground #${config.colorScheme.palette.base05}
		inactive_tab_background #${config.colorScheme.palette.base01}
		inactive_tab_foreground #${config.colorScheme.palette.base04}
		tab_bar_background #${config.colorScheme.palette.base01}

		# normal
		color0 #${config.colorScheme.palette.base00}
		color1 #${config.colorScheme.palette.base08}
		color2 #${config.colorScheme.palette.base0B}
		color3 #${config.colorScheme.palette.base0A}
		color4 #${config.colorScheme.palette.base0D}
		color5 #${config.colorScheme.palette.base0E}
		color6 #${config.colorScheme.palette.base0C}
		color7 #${config.colorScheme.palette.base05}

		# bright
		color8 #${config.colorScheme.palette.base03}
		color9 #${config.colorScheme.palette.base09}
		color10 #${config.colorScheme.palette.base01}
		color11 #${config.colorScheme.palette.base02}
		color12 #${config.colorScheme.palette.base04}
		color13 #${config.colorScheme.palette.base06}
		color14 #${config.colorScheme.palette.base0F}
		color15 #${config.colorScheme.palette.base07}

		'';
	};

}

