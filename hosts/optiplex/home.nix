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
    #
    # Ordered smallest-first on purpose: the uplink is 5.7 Mbit/s, so Camera
    # alone is an overnight job. Everything above it totals ~4 GB and is done
    # inside a couple of hours.
    backup.paths = [
      "/mnt/data/jonny/obsidian-backup" # 192 M
      "/mnt/data/jonny/Second-Brain_old" # 193 M
      "/mnt/data/jonny/ToPhone" # 255 M
      "/mnt/data/jonny/Thinking-Into-Results" # 587 M
      "/mnt/data/jonny/Pictures" # 884 M
      "/home/jonny" # 1.3 G
      "/mnt/data/jonny/Camera" # 20 G — the long pole
    ];
  };

  home.sessionVariables = {
    # Chromium/Electron apps use the Wayland backend rather than XWayland.
    NIXOS_OZONE_WL = "1";
  };
}
