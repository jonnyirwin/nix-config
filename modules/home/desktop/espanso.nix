{ lib, pkgs, config, osConfig, ... }:

let
  cfg = config.jonny.desktop;

  # Only optiplex has sops turned on so far (jonny.secrets.enable), and the
  # other desktops would fail to evaluate on a bare attribute access. Hosts
  # without the secret simply get no :email match rather than a broken build —
  # enable jonny.secrets there and add the key to secrets/<host>.yaml to get it.
  emailSecret = osConfig.sops.secrets.espanso_email or null;
in
{
  config = lib.mkIf cfg.enable {
    # Wayland backend needs /dev/uinput access — see
    # modules/nixos/desktop/espanso.nix for the system-level half of this.
    services.espanso = {
      enable = true;
      waylandSupport = true;

      # The address is deliberately not written here: this tree is public on
      # GitHub, and a plaintext address in it is free food for scrapers. It
      # lives in secrets/optiplex.yaml, sops-nix decrypts it at activation to a
      # file only jonny can read, and espanso reads that file at expansion
      # time. What ends up in the world-readable nix store is the path, not the
      # value.
      matches.base.matches = lib.optional (emailSecret != null) {
        trigger = ":email";
        replace = "{{address}}";
        vars = [{
          name = "address";
          type = "shell";
          params = {
            cmd = "${pkgs.coreutils}/bin/cat ${emailSecret.path}";
            trim = true;
          };
        }];
      };
    };
  };
}
