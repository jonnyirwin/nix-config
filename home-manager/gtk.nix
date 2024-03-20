{ config, pkgs, nix-colors, ... }:
let
	inherit (nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in{
	gtk = {
		enable = true;
		font = {
			name = "Inter";
			size = 12;
		};
		theme = {
			name = "${config.colorScheme.slug}";
			package = gtkThemeFromScheme {
				scheme = config.colorScheme;
			};
		};
		iconTheme = {
			name = "Papirus";
			package = pkgs.papirus-icon-theme;
		};
	};
}
