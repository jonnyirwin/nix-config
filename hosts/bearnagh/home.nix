# Home Manager config specific to bearnagh. Shared user config lives in
# modules/home; this file should stay small enough to read at a glance.
{
  jonny = {
    # desktop.enable, desktop.compositor and the whole of jonny.theme are
    # inherited from hosts/bearnagh/default.nix via osConfig.
    #
    # No `jonny.desktop.outputs` here either: optiplex declares one because it
    # pins a resolution and a rotation on a fixed panel. The internal display
    # is the only output this machine has most of the time, and sway picks its
    # native 1920x1080 on its own. Add an entry when there is a docked layout
    # worth making permanent — wdisplays (Mod+Shift+D) for ad-hoc changes.
    backup = {
      # Must not be left at the default, which is "backup/optiplex" — two
      # machines pointing at one remote directory would interleave their
      # uploads into a single tree with no way to tell which came from where.
      destination = "backup/bearnagh";

      # Same convention as optiplex: one hand-curated collection point rather
      # than a list of scattered sources. What is in ~/backup is what goes
      # off-machine, so deciding what deserves backing up is a file manager
      # operation rather than an edit to this file.
      #
      # Note ~/backup lives on the OS disk, which a reinstall wipes. That is
      # the point — it is a staging area for the upload, not a backup itself.
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
