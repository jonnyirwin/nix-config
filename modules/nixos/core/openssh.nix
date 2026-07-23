{ lib, config, ... }:

let
  cfg = config.jonny.services.openssh;
in
{
  options.jonny.services.openssh.enable =
    lib.mkEnableOption "the OpenSSH daemon (key auth only, no root login)";

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "no";
    };
  };
}
