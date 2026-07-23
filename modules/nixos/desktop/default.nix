{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  imports = [
    # ---- Compositor-agnostic ----
    ./audio.nix
    ./bluetooth.nix
    ./fonts.nix
    ./graphics.nix
    ./greetd.nix
    ./onepassword.nix
    ./portals.nix

    # ---- Compositor-specific ----
    ./compositors/sway.nix
  ];

  options.jonny.desktop = {
    enable = lib.mkEnableOption "the graphical desktop (session, audio, portals, GPU)";

    compositor = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "sway" ]);
      default = null;
      description = ''
        Which Wayland compositor the session runs. Mirrors the Home Manager
        option of the same name — mkHost does not wire them together, so a host
        sets this once at the system level and the HM side reads it via
        osConfig.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # greetd launches this; kept as an option so it stays in step with the
    # compositor rather than being spelled out in the greeter command.
    services.displayManager.defaultSession = lib.mkDefault cfg.compositor;
  };
}
