{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # greetd is lightweight and Wayland-native. This replaces the hand-deployed
    # /etc/greetd config that used to live in ~/.dotfiles/greetd/ with a deploy.sh.
    services.greetd = {
      enable = true;
      settings.default_session = {
        # Follows jonny.desktop.compositor rather than naming one, so switching
        # compositor does not leave the greeter launching the old one.
        command = "${lib.getExe pkgs.tuigreet} --time --cmd ${cfg.compositor}";
        user = "greeter";
      };
    };
  };
}
