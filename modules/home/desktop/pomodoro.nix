{ config, lib, pkgs, ... }:

# The pomodoro suite is ~700 lines of working bash carried over from
# ~/.dotfiles/waybar/scripts. It is vendored verbatim in ./pomodoro/ rather
# than rewritten, with three changes:
#
#   * pomodoro.conf is generated from the options below and passed in as
#     $POMODORO_CONF. The old pomodoro-config.sh sed-ed that file in place,
#     which cannot work from the read-only store — durations are Nix options
#     now, and that script is gone.
#   * state moved from /tmp to $XDG_STATE_HOME/pomodoro
#   * the scripts call each other by name on PATH rather than by $SCRIPT_DIR
#
# These use writeShellScriptBin + a PATH wrapper rather than
# writeShellApplication (as the scripts in scripts.nix do) because the vendored
# code predates shellcheck-clean discipline and `set -euo pipefail` would change
# its control flow. New scripts should use writeShellApplication.

let
  cfg = config.jonny.desktop.pomodoro;

  pomodoroConf = pkgs.writeText "pomodoro.conf" ''
    WORK_TIME_MINUTES=${toString cfg.workMinutes}
    SHORT_BREAK_MINUTES=${toString cfg.shortBreakMinutes}
    LONG_BREAK_MINUTES=${toString cfg.longBreakMinutes}
    SESSIONS_BEFORE_LONG_BREAK=${toString cfg.sessionsBeforeLongBreak}
    COMPLETED_SESSIONS=0
    ENABLE_NOTIFICATIONS=${lib.boolToString cfg.notifications}
    NOTIFICATION_SOUND=${lib.boolToString cfg.notificationSound}
    WORK_ICON="󰔛"
    BREAK_ICON="☕"
    PAUSED_ICON="⏸️"
    FLOATING_WINDOW_SIZE="400x300"
    FLOATING_WINDOW_POSITION="center"
  '';

  runtimeInputs = with pkgs; [
    bash
    coreutils
    gnused
    gnugrep
    procps
    libnotify
    rofi
    kitty
    sway # swaymsg, used by the break window
  ];

  mkVendored = name: source: pkgs.symlinkJoin {
    inherit name;
    paths = [ (pkgs.writeShellScriptBin name (builtins.readFile source)) ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/${name} \
        --prefix PATH : ${lib.makeBinPath runtimeInputs} \
        --set POMODORO_CONF ${pomodoroConf}
    '';
    meta.mainProgram = name;
  };

  # Each script shells out to the others by name, so they must all be on one
  # another's PATH — hence the mutually-recursive `runtimeInputs` extension.
  pomodoro = mkVendored "pomodoro" ./pomodoro/pomodoro.sh;
  pomodoro-menu = mkVendored "pomodoro-menu" ./pomodoro/pomodoro-menu.sh;
  pomodoro-break-window = mkVendored "pomodoro-break-window" ./pomodoro/pomodoro-break-window.sh;

  suite = pkgs.symlinkJoin {
    name = "pomodoro-suite";
    paths = [ pomodoro pomodoro-menu pomodoro-break-window ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in pomodoro pomodoro-menu pomodoro-break-window; do
        wrapProgram $out/bin/$bin --prefix PATH : $out/bin
      done
    '';
    meta.mainProgram = "pomodoro";
  };
in
{
  options.jonny.desktop.pomodoro = {
    enable = lib.mkEnableOption "the pomodoro timer and its waybar module" // { default = true; };

    workMinutes = lib.mkOption {
      type = lib.types.int;
      default = 50;
    };

    shortBreakMinutes = lib.mkOption {
      type = lib.types.int;
      default = 10;
    };

    longBreakMinutes = lib.mkOption {
      type = lib.types.int;
      default = 30;
    };

    sessionsBeforeLongBreak = lib.mkOption {
      type = lib.types.int;
      default = 4;
    };

    notifications = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    notificationSound = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = suite;
      description = "The wrapped pomodoro suite; waybar and sway reference this.";
    };
  };

  config = lib.mkIf (config.jonny.desktop.enable && cfg.enable) {
    home.packages = [ suite ];
  };
}
