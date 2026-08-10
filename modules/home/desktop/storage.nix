{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # The piece that actually automounts. udisks2 (system side,
    # modules/nixos/desktop/storage.nix) only exposes devices over D-Bus and
    # mounts on request; something has to be listening and doing the asking,
    # and that is udiskie.
    #
    # A systemd user unit rather than a sway `exec`, because `exec` runs once
    # at session start with no ordering against udisks2 and no way back if the
    # process goes away. That exact failure is why this module exists: udiskie
    # started before udisks2 was ever enabled, found nothing on the bus, exited,
    # and — `exec` having already fired — was never retried, so cards stayed
    # unmounted for the rest of the session. Bound to graphical-session.target
    # it starts in the right order, and `systemctl --user restart udiskie`
    # recovers a session without logging out. Same pattern as waybar.
    services.udiskie = {
      enable = true;
      automount = true;
      # Matches the old `--no-notify`. mako is for things needing attention;
      # a card appearing in Thunar is its own feedback.
      notify = false;
      # Thunar's sidebar already has the eject affordances, so a second tray
      # icon next to blueman and nm-applet would only be noise.
      tray = "never";
    };

    # The module does not set a restart policy, so a crashed udiskie stays
    # dead until the next login — the same silent, session-long breakage as
    # before, just reached a different way.
    systemd.user.services.udiskie.Service = {
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
