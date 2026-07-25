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

    backup = {
      # Photos only, by choice — everything else here is either reproducible or
      # accepted as expendable. The staging copy on the SATA disk still covers
      # the rest through the disk migration.
      #
      # If that ever changes, the candidates are small: Keepass is 336 KB,
      # Documents 136 MB, pi-backup 1.7 GB — minutes, not hours.
      #
      # Ordered smallest-first: the uplink is 5.7 Mbit/s, so Pictures is done
      # within the hour while Camera runs overnight.
      paths = [
        "/mnt/data/jonny/Pictures" # 884 M
        "/home/jonny/Downloads/Takeout/Google Photos" # 8.6 G
        "/mnt/data/jonny/Camera" # 20 G
        "/mnt/data/photo-backup" # 48 G (bigDrive, smallDrive, iPhone Backups)
      ];

      # Appends to the shared defaults rather than replacing them.
      extraExclude = [
        # 11 G of checkouts that all have remotes. The only thing here that is
        # not on a server somewhere is uncommitted work.
        "git/**"

        # Google Takeout writes a tiny (~700 B) `*.supplemental-metadata.json`
        # sidecar next to every photo — thousands of them. Each is a full API
        # round-trip, so they dominate the runtime while adding ~nothing in
        # bytes, exactly like the .thumbnails case in the shared excludes. The
        # bare `*.json` (not the specific sidecar name) is deliberate: Takeout
        # truncates the sidecar filename when the path is long, so the full
        # name does not reliably match. These are only photo paths, where a
        # stray .json is never the irreplaceable thing.
        "*.json"
      ];
    };
  };

  home.sessionVariables = {
    # Chromium/Electron apps use the Wayland backend rather than XWayland.
    NIXOS_OZONE_WL = "1";
  };
}
