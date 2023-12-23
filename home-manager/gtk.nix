{ config, pkgs, ... }:
{
	gtk = {
		enable = true;
		font = {
			name = "Inter";
			size = 12;
		};
		theme = {
			name = "Catppuccin-Mocha-Blue-Compact-Dark";
			package = pkgs.catppuccin-gtk.override {
				size = "compact";
				tweaks = [ "rimless" "black" ];
				variant = "mocha";
			};
		};
		iconTheme = {
			name = "Papirus";
			package = pkgs.papirus-icon-theme;
		};
	};
}
