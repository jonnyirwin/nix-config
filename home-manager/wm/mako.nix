{ config, ... }:
{
	services.mako = {
		enable = true;
		backgroundColor = config.colorScheme.palette.base00; 
		textColor = config.colorScheme.palette.base05;
		borderColor = config.colorScheme.palette.base0D;
		anchor = "bottom-center";
		borderRadius = 5;
		font = "Inter 12";
		height = 50;
		width = 500;
	};
}
