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
      # One collection point rather than a list of scattered sources: things
      # get copied into ~/backup by hand, and whatever is in there is what
      # goes off-machine. Deciding what deserves backing up is then a file
      # manager operation, not an edit to this file.
      #
      # The paths this replaced — Pictures, Takeout, Camera, photo-backup —
      # are already uploaded and STAY uploaded. `rclone copy` never deletes at
      # the destination, so dropping a path here only stops it being revisited;
      # onedrive:backup/optiplex/{Pictures,Camera,...} are untouched.
      #
      # Note ~/backup lives on the OS disk, which the reinstall wipes. That is
      # the point — it is a staging area for the upload, not a backup itself.
      # No extraExclude: with a single hand-curated path there is nothing to
      # carve out. `git/**` and `*.json` existed to skip checkouts and Google
      # Takeout sidecars in the old scattered photo paths; neither applies to
      # ~/backup, and a pattern that outlives its reason is how an exclude
      # list quietly starts dropping things you meant to keep. The shared
      # defaults in modules/home/backup.nix still apply.
      paths = [
        "/home/jonny/backup"
      ];
    };
  };

  home.sessionVariables = {
    # Chromium/Electron apps use the Wayland backend rather than XWayland.
    NIXOS_OZONE_WL = "1";
  };
}
