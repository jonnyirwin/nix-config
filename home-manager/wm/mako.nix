{ config, ... }:
{
	services.mako = {
		enable = true;
		backgroundColor = config.colorScheme.colors.base00; 
		textColor = config.colorScheme.colors.base05;
		borderColor = config.colorScheme.colors.base0D;
		anchor = "bottom-center";
		borderRadius = 5;
		font = "Inter 12";
		height = 50;
		width = 500;
	};
}
