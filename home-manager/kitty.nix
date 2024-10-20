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

symbol_map U+E000-U+E00D Symbols Nerd Font
symbol_map U+e0a0-U+e0a2,U+e0b0-U+e0b3 Symbols Nerd Font
symbol_map U+e0a3-U+e0a3,U+e0b4-U+e0c8,U+e0cc-U+e0d2,U+e0d4-U+e0d4 Symbols Nerd Font
symbol_map U+e5fa-U+e62b Symbols Nerd Font
symbol_map U+e700-U+e7c5 Symbols Nerd Font
symbol_map U+f000-U+f2e0 Symbols Nerd Font
symbol_map U+e200-U+e2a9 Symbols Nerd Font
symbol_map U+f400-U+f4a8,U+2665-U+2665,U+26A1-U+26A1,U+f27c-U+f27c Symbols Nerd Font
symbol_map U+F300-U+F313 Symbols Nerd Font
symbol_map U+23fb-U+23fe,U+2b58-U+2b58 Symbols Nerd Font
symbol_map U+f500-U+fd46 Symbols Nerd Font
symbol_map U+e300-U+e3eb Symbols Nerd Font
symbol_map U+21B5,U+25B8,U+2605,U+2630,U+2632,U+2714,U+E0A3,U+E615,U+E62B Symbols Nerd Font
		'';
	};

}
