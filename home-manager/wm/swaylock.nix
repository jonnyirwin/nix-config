{ config, lib, pkgs, ... }:
{
	services.swayidle = {
		enable = true;
		events = [ 
			{ event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -f -c 000000"; }
			{ event = "after-resume"; command = "swaymsg \"output * dpms on\""; }
		];
		timeouts = [
			{ timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f -c 000000"; }
			{ timeout = 600; command = "swaymsg \"output * dpms off \""; }
		];
	};

	programs.swaylock = {
		enable = true;
		settings = {
			background = "#000000";
		};
	};


}
