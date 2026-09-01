{ config, lib, ... }:

# Automatic wallpaper. One fetcher per source in
# modules/home/desktop/scripts.nix fills ~/Pictures/Wallpapers: bing-wallpaper
# takes Bing's daily photograph, nasa-wallpaper takes NASA's Astronomy Picture
# of the Day. This timer runs the ones that are switched on, once a day, and
# then advances the rotation. The lock screen picks up the same directory on
# its own (see scripts.nix's lock-screen script), so no separate wiring is
# needed there.
#
# Deliberately not called wallpaper.service: that name belongs to the transient
# unit `wallpaper` starts for swaybg, and reusing it would have this oneshot
# tear the running background down every morning.
let
  cfg = config.jonny.desktop;
  s = cfg.scripts;

  enabled = lib.attrNames (lib.filterAttrs (_: on: on) cfg.wallpaper.sources);
in
{
  options.jonny.desktop.wallpaper.sources = lib.mkOption {
    type = lib.types.attrsOf lib.types.bool;
    default = {
      bing = true;
      nasa = false;
    };
    example = { bing = true; nasa = true; };
    description = ''
      Which collections feed the rotation. A source named `x` is fetched by
      the `x-wallpaper` script and lands in `~/Pictures/Wallpapers/x`; both
      follow from the name, so switching one on or off is this one word.

      Switching a source off prunes its directory from the rotation and stops
      the daily fetch. It does not delete anything already downloaded, so
      turning it back on restores the archive rather than starting again from
      an empty directory.

      APOD is off by default. It is an astronomy feed rather than a wallpaper
      feed — a third of what it sent was below the resolution floor in
      nasa-wallpaper, and much of the rest is a diagram.
    '';
  };

  config = lib.mkIf cfg.enable {
    assertions = map
      (name: {
        assertion = cfg.scripts ? "${name}-wallpaper";
        message = ''
          jonny.desktop.wallpaper.sources.${name} has no matching
          "${name}-wallpaper" script in modules/home/desktop/scripts.nix.
        '';
      })
      (lib.attrNames cfg.wallpaper.sources);

    # With every source switched off the rotation still works — it just walks
    # whatever you put in ~/Pictures/Wallpapers yourself — but there is nothing
    # left to fetch, so the timer would fire daily to do nothing at all.
    systemd.user.services = lib.mkIf (enabled != [ ]) {
      wallpaper-fetch = {
        Unit.Description = "Fetch the day's wallpapers and advance the rotation";
        Service = {
          Type = "oneshot";
          # One ExecStart line per source rather than one script: a oneshot
          # runs them in order, and either source being down for the day
          # should not stop the other from arriving.
          ExecStart = map (name: lib.getExe s."${name}-wallpaper") enabled;
          ExecStartPost = "${lib.getExe s.wallpaper} next";
        };
      };
    };

    systemd.user.timers = lib.mkIf (enabled != [ ]) {
      wallpaper-fetch = {
        Unit.Description = "Daily wallpaper refresh";
        Timer = {
          # Not "daily" (00:00 local): APOD rolls over at midnight US Eastern,
          # so a local-midnight run in BST fires at 23:00 UTC and still sees
          # yesterday's picture. 06:00 UTC clears the rollover year-round, and
          # Bing's day has turned over well before then too.
          OnCalendar = "*-*-* 06:00:00 UTC";
          # Runs on the next login/boot if the machine was off at the scheduled
          # time — including immediately on first-ever activation, since there
          # is no recorded last-run yet.
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
