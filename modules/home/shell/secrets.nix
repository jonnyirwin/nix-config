{ osConfig, lib, ... }:

let
  # Present only once a secret named api_keys is declared in
  # modules/nixos/core/secrets.nix. Until then this module is inert.
  apiKeys = osConfig.sops.secrets.api_keys or null;
in
{
  # Replaces the old conf.d/secrets.fish, which sourced a hand-copied
  # ~/.config/fish.secrets/api_keys.fish (chmod 600, outside git). The file is
  # now decrypted at activation from secrets/secrets.yaml, so a fresh machine
  # needs only its SSH host key rather than a manual copy step.
  programs.fish.interactiveShellInit = lib.mkIf (apiKeys != null) ''
    if test -r ${apiKeys.path}
        # The file is `set -gx` lines; sourcing exports them into this shell,
        # and new tmux panes inherit them through the normal environment path.
        source ${apiKeys.path}
    end
  '';
}
