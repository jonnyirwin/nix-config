{ config, lib, pkgs, ... }:
{
	programs.kitty = {
		enable = true;
		theme = "Tokyo Night";
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
	};
}

