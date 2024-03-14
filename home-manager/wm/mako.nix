{ config, ... }:
{
	services.mako = 
	{
		enable = true;
		backgroundColor = "#${config.colorScheme.palette.base00}"; 
		textColor = "#${config.colorScheme.palette.base08}";
		borderColor = "#${config.colorScheme.palette.base08}";
		borderSize = 1;
		anchor = "top-right";
		borderRadius = 5;
		font = "Inter 14";
		icons = true;
		defaultTimeout = 5000;
		progressColor = "over #${config.colorScheme.palette.base0A}";
		margin = "10";
		padding = "10,16";
		width = 275;
	};
}
