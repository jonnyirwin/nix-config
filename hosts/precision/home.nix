# Home Manager config specific to precision. Shared user config lives in
# modules/home; this file should stay small enough to read at a glance.
{
  jonny = {
    # desktop.enable, desktop.compositor and the whole of jonny.theme are
    # inherited from hosts/precision/default.nix via osConfig. No
    # jonny.desktop.outputs yet — nothing is plugged in; add an entry once a
    # monitor is attached and its layout is worth pinning.
    backup = {
      # Must not be left at the default, "backup/optiplex" — four machines
      # pointing at one remote directory would interleave their uploads into a
      # single tree with no way to tell which came from where.
      destination = "backup/precision";

      # Same convention as the other hosts: one hand-curated collection point
      # rather than a list of scattered sources.
      #
      # Deliberately NOT /mnt/archive. That disk holds ~1.2 TB, it is already
      # the place things get archived *to*, and pointing an rclone job at it
      # would try to push the lot over a 5.7 Mbit uplink.
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
