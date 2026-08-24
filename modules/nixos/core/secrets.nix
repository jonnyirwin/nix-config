{ lib, config, inputs, ... }:

let
  cfg = config.jonny.secrets;
  hostFile = ../../../secrets + "/${config.networking.hostName}.yaml";
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.jonny.secrets.enable =
    lib.mkEnableOption "sops-nix secret decryption at activation";

  config = lib.mkIf cfg.enable {
    sops = {
      # Per-host by convention, so adding a machine never means re-encrypting
      # secrets the other machines own. Shared values go in secrets/common.yaml
      # and are declared with an explicit `sopsFile`.
      defaultSopsFile = lib.mkIf (builtins.pathExists hostFile) hostFile;

      # The host's own SSH key doubles as the age identity — see .sops.yaml.
      # No separate key to generate, copy, or lose.
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      gnupg.sshKeyPaths = [ ];

      # Declare secrets here as you add them, then reference
      # config.sops.secrets.<name>.path from the module that consumes it.
      # Fish already sources such a file if one is declared — see
      # modules/home/shell/secrets.nix.
      secrets = {
        # Personal email address. Kept here rather than inline in the espanso
        # match because this repo is public — see
        # modules/home/desktop/espanso.nix, which reads it through osConfig.
        espanso_email = {
          owner = "jonny";
          mode = "0400";
        };
      };
    };
  };
}
