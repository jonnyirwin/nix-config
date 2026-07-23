# Home Manager config specific to optiplex. Shared user config lives in
# modules/home; this file should stay small enough to read at a glance.
{
  jonny = {
    desktop = {
      enable = true;
      compositor = "sway";

      # Was config.d/display-settings.conf, rewritten at runtime by
      # resolution-switcher.sh. Portrait 1440p on the sole DisplayPort output.
      outputs."DP-1" = {
        resolution = "2560x1440";
        transform = "90";
      };
    };

    # Change either line to re-theme everything. Schemes: catppuccin-{latte,
    # frappe,macchiato,mocha}, gruvbox-dark, nord — see lib/schemes/.
    # The accent is named by hue, so it keeps its meaning across schemes:
    # "purple" is Catppuccin's mauve, Gruvbox's bright purple, Nord's nord15.
    theme = {
      scheme = "catppuccin-mocha";
      accent = "purple";
    };

    # What cannot be regenerated. Deliberately excludes /mnt/data/jonny/git
    # (pushed to remotes), RetroPie and pi-backup (re-obtainable), and anything
    # this flake rebuilds.
    backup.paths = [
      "/mnt/data/jonny/Camera"
      "/mnt/data/jonny/Pictures"
      "/mnt/data/jonny/obsidian-backup"
      "/mnt/data/jonny/Second-Brain_old"
      "/mnt/data/jonny/Thinking-Into-Results"
      "/mnt/data/jonny/ToPhone"
      "/home/jonny"
    ];
  };

  home.sessionVariables = {
    # Chromium/Electron apps use the Wayland backend rather than XWayland.
    NIXOS_OZONE_WL = "1";
  };
}
