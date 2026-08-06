{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  imports = [
    # ---- Compositor-agnostic ----
    ./audio.nix
    ./avahi.nix
    ./bluetooth.nix
    ./espanso.nix
    ./fonts.nix
    ./graphics.nix
    ./localsend.nix
    ./plymouth.nix
    ./printing.nix
    ./scanning.nix
    ./sddm.nix
    ./onepassword.nix
    ./portals.nix
    ./steam.nix
    ./storage.nix

    # ---- Compositor-specific ----
    ./compositors/sway.nix
  ];

  options.jonny.desktop = {
    enable = lib.mkEnableOption "the graphical desktop (session, audio, portals, GPU)";

    compositor = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "sway" ]);
      default = null;
      description = ''
        Which Wayland compositor the session runs. This is the host's single
        declaration: the Home Manager option of the same name defaults from it
        via osConfig, so setting it here configures both the system session
        (seat, portals, greeter target) and the user's compositor config.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # SDDM launches this; kept as an option so it stays in step with the
    # compositor rather than being spelled out in the greeter command.
    services.displayManager.defaultSession = lib.mkDefault cfg.compositor;
  };
}
