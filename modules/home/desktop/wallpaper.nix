{ config, lib, ... }:

# Automatic wallpaper: modules/home/desktop/scripts.nix's nasa-wallpaper
# fetches NASA's Astronomy Picture of the Day into ~/Pictures/Wallpapers/nasa,
# and this timer applies it (via random-wallpaper) once a day. The lock
# screen picks up the same directory on its own (see scripts.nix's
# lock-screen script), so no separate wiring is needed there.
let
  cfg = config.jonny.desktop;
  s = cfg.scripts;
in
{
  config = lib.mkIf cfg.enable {
    systemd.user.services.nasa-wallpaper = {
      Unit.Description = "Fetch NASA's Astronomy Picture of the Day and apply it as the wallpaper";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe s.nasa-wallpaper;
        ExecStartPost = lib.getExe s.random-wallpaper;
      };
    };

    systemd.user.timers.nasa-wallpaper = {
      Unit.Description = "Daily NASA wallpaper refresh";
      Timer = {
        # Not "daily" (00:00 local): APOD rolls over at midnight US Eastern,
        # so a local-midnight run in BST fires at 23:00 UTC and still sees
        # yesterday's picture. 06:00 UTC clears the rollover year-round.
        OnCalendar = "*-*-* 06:00:00 UTC";
        # Runs on the next login/boot if the machine was off at the scheduled
        # time — including immediately on first-ever activation, since there
        # is no recorded last-run yet.
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
