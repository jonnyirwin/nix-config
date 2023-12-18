{ config, lib, pkgs, ... }:
{
	services.mako = {
		enable = true;
		backgroundColor = "#285577FF";
		anchor = "bottom-center";
		borderRadius = 5;
		font = "Inter 12";
		height = 50;
		width = 500;
	};
}
