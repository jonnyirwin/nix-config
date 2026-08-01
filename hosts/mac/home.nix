# Home Manager config specific to mac. Shared user config lives in
# modules/home; this file should stay small enough to read at a glance.
{
  jonny = {
    # desktop.enable, desktop.compositor and the whole of jonny.theme are
    # inherited from hosts/mac/default.nix via osConfig. No
    # jonny.desktop.outputs: the internal panel is the only display, and sway
    # picks its native mode without being told.
    backup = {
      # Must not be left at the default, "backup/optiplex" — three machines
      # pointing at one remote directory would interleave their uploads into a
      # single tree with no way to tell which came from where.
      destination = "backup/mac";

      # Same convention as the other hosts: one hand-curated collection point
      # rather than a list of scattered sources.
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
