# Home Manager config specific to optiplex. Shared user config lives in
# modules/home; this file should stay small enough to read at a glance.
{
  jonny = {
    desktop = {
      enable = true;

      # Was config.d/display-settings.conf, rewritten at runtime by
      # resolution-switcher.sh. Portrait 1440p on the sole DisplayPort output.
      outputs."DP-1" = {
        resolution = "2560x1440";
        transform = "90";
      };
    };

    theme = {
      flavor = "mocha";
      accent = "mauve";
    };
  };

  home.sessionVariables = {
    # Chromium/Electron apps use the Wayland backend rather than XWayland.
    NIXOS_OZONE_WL = "1";
  };
}
