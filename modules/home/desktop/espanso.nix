{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Wayland backend needs /dev/uinput access — see
    # modules/nixos/desktop/espanso.nix for the system-level half of this.
    services.espanso = {
      enable = true;
      waylandSupport = true;

      # Seed with one real match rather than a placeholder; add more here as
      # they come up.
      matches.base.matches = [
        { trigger = ":email"; replace = "jonny@jbi.im"; }
      ];
    };
  };
}
