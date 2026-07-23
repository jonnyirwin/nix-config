{ lib, config, ... }:

let
  cfg = config.jonny.security;
in
{
  options.jonny.security = {
    passwordlessSudo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Let the wheel group sudo without a password. Convenient on a
        single-user machine, but it means any process running as your user can
        become root with no prompt. Off by default; opt in per host.
      '';
    };
  };

  config = {
    security.sudo.wheelNeedsPassword = !cfg.passwordlessSudo;

    # Required by GUI apps that escalate privileges (gparted, 1Password unlock).
    security.polkit.enable = true;
  };
}
