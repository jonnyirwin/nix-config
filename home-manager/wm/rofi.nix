{ config, lib, pkgs, ...}:
{
	programs.rofi = {
		enable = true;
		package = pkgs.rofi-wayland;
		terminal = config.wayland.windowManager.sway.config.terminal;
		extraConfig = {
    modi = "drun,run";

    show-icons = true;
    drun-show-actions = true;

    sort = true;

    run-command = "${pkgs.sway}/bin/swaymsg exec -- {cmd}";
    drun-url-launcher = "${pkgs.sway}/bin/swaymsg -- ${pkgs.xdg-utils}/bin/xdg-open";
  };

	};
}
