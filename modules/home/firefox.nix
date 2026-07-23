{ config, lib, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Managed here rather than installed as a bare package so enterprise
    # policies apply. ExtensionSettings force-installs the 1Password extension
    # onto every profile; it unlocks through the native-messaging bridge
    # provided by programs._1password-gui at the system level.
    programs.firefox = {
      enable = true;

      # The profile already lives here; this aligns HM with reality rather than
      # waiting for the default to flip at stateVersion 26.05. No data moves.
      configPath = "${config.xdg.configHome}/mozilla/firefox";

      policies.ExtensionSettings = {
        # 1Password – Password Manager
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
}
