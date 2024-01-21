{ config, pkgs, ...}:
{
	programs.rofi = {
		enable = true;
		package = pkgs.rofi-wayland;
		inherit (config.wayland.windowManager.sway.config) terminal;
		font = "Inter 18";
		#theme = "Monokai";
		extraConfig = {
    			modi = "drun";
    			show-icons = true;
					fixed-num-lines = true;
		};
	};
}		
