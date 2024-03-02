{
  config,
  lib,
  ...
}:
{
	imports = [
		./wm/i3.nix
		./wm/sway.nix
	];

  options = {
    environment = {
      desktop = lib.mkOption {
        type = lib.types.enum ["sway" "i3"];
        default = "sway";
      };
    };
  };
}
