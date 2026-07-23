{ config, osConfig, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  fonts = config.jonny.theme.fonts;
  s = cfg.scripts;

  pomodoro = config.jonny.desktop.pomodoro;
  pomodoroBin = name: "${pomodoro.package}/bin/${name}";

  # Waybar names its workspace widget after the compositor. Deriving it here is
  # the only compositor-specific thing left in this file.
  workspaceModule = "${cfg.compositor}/workspaces";

  # Icon coverage is declared once in jonny.theme.fonts.fallback rather than
  # being spelled out in this CSS.
  fontStack = lib.concatMapStringsSep ", " (f: ''"${f}"'')
    ([ fonts.ui.family ] ++ fonts.fallback) + ", monospace";
in
{
  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;

      # Bound to the compositor's session target rather than launched from its
      # config. This replaces waybar-supervisor.sh, which existed only to work
      # around a race with the old unit's `Requisite=graphical-session.target`:
      # that failed instantly if the target wasn't up yet when the exec fired.
      systemd = {
        enable = true;
        targets = [ cfg.sessionTarget ];
      };

      settings.mainBar = {
        layer = "top";
        position = "top";

        modules-left = [ "custom/pomodoro" workspaceModule ];
        modules-center = [ "custom/music" ];
        modules-right = [
          "custom/audio-output"
          "pulseaudio"
          "backlight"
          "battery"
          "custom/idle-inhibitor"
          "clock"
          "tray"
        ];

        ${workspaceModule} = {
          disable-scroll = true;
          sort-by-number = true;
          format = "{name}";
        };

        tray = {
          icon-size = 21;
          spacing = 10;
        };

        "custom/music" = {
          format = "󰝚 {}";
          escape = true;
          interval = 5;
          tooltip = false;
          exec = "${lib.getExe pkgs.playerctl} metadata --format='{{ title }}'";
          on-click = "${lib.getExe pkgs.playerctl} play-pause";
          max-length = 50;
        };

        "custom/pomodoro" = lib.mkIf pomodoro.enable {
          format = "{}";
          return-type = "json";
          interval = 1;
          exec = "${pomodoroBin "pomodoro"} display";
          on-click = pomodoroBin "pomodoro-menu";
          escape = true;
        };

        clock = {
          # Follows the system timezone rather than restating it — these used to
          # disagree (waybar said Europe/Isle_of_Man, NixOS said Europe/London).
          timezone = osConfig.time.timeZone;
          format = "󰥔 {:%H:%M}";
          format-alt = "󰃭 {:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        backlight = {
          format = "{icon} {percent:>3}%";
          format-icons = [ "" "" "" ];
          on-scroll-up = "${lib.getExe pkgs.brightnessctl} set 1%+";
          on-scroll-down = "${lib.getExe pkgs.brightnessctl} set 1%-";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity:>3}%";
          format-charging = "󰂄 {capacity:>3}%";
          format-plugged = "󱐥 {capacity:>3}%";
          format-alt = "{icon}";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        };

        "custom/audio-output" = {
          format = "{}";
          interval = 2;
          exec = lib.getExe s.audio-output;
          on-click = lib.getExe s.audio-switch;
        };

        pulseaudio = {
          format = "{icon} {volume:>3}%";
          format-muted = " ---%";
          format-icons.default = [ "" "" "" ];
          on-click = lib.getExe pkgs.pavucontrol;
          on-click-right = lib.getExe s.audio-switch;
        };

        "custom/idle-inhibitor" = {
          interval = "once";
          signal = 10;
          exec = lib.getExe s.idle-inhibitor-status;
          on-click = lib.getExe s.idle-inhibitor-toggle;
          tooltip = false;
        };
      };

      # Capsule pills on a mantle bar — the same vocabulary as tmux's status
      # segments and rofi's selection. Colours come from jonny.theme.
      style = ''
        * {
          font-family: ${fontStack};
          font-size: ${toString fonts.ui.size}px;
          min-height: 0;
        }

        #waybar {
          background: ${p.bgAlt};
          color: ${p.fg};
          margin: 0;
          padding: 4px 0;
        }

        /* ── Workspaces ───────────────────────── */

        #workspaces {
          background: transparent;
          border: none;
          margin: 0 4px;
          padding: 0;
        }

        #workspaces button {
          background: ${p.surface};
          color: ${p.fgMuted};
          border-radius: 999px;
          padding: 0 10px;
          margin: 2px 3px;
          min-height: 24px;
          border: none;
          box-shadow: none;
          transition: color 120ms ease, background 120ms ease;
        }

        #workspaces button:hover {
          color: ${p.fg};
          background: ${p.surfaceAlt};
        }

        #workspaces button.focused {
          color: ${p.bgInset};
          background: ${p.accent};
        }

        /* ── Status pills ─────────────────────── */

        #custom-music,
        #custom-pomodoro,
        #tray,
        #backlight,
        #clock,
        #battery,
        #cpu,
        #memory,
        #custom-ip,
        #pulseaudio,
        #custom-audio-output,
        #custom-idle-inhibitor {
          background: ${p.surface};
          border: none;
          border-radius: 999px;
          padding: 0 12px;
          margin: 2px 3px;
          min-height: 24px;
        }

        .modules-right > widget:first-child > * {
          border-radius: 999px;
          margin-left: 3px;
          padding-left: 12px;
        }

        /* ── Per-module colour ────────────────── */

        #clock { color: ${p.info}; }

        #battery { color: ${p.success}; }
        #battery.charging { color: ${p.hues.cyan}; }
        #battery.warning:not(.charging) { color: ${p.warning}; }
        #battery.critical:not(.charging) { color: ${p.error}; }

        #backlight { color: ${p.warning}; }

        #pulseaudio,
        #custom-audio-output { color: ${p.hues.blue}; }

        #cpu { color: ${p.success}; }
        #memory { color: ${p.hues.cyan}; }
        #custom-ip { color: ${p.hues.cyan}; }
        #custom-ip.internal { color: ${p.fgMuted}; }

        #custom-idle-inhibitor { color: ${p.fgMuted}; }

        #tray { margin-right: 8px; }

        #custom-music { color: ${p.accent}; }

        #custom-pomodoro { color: ${p.hues.orange}; }
        #custom-pomodoro.running { color: ${p.success}; }
        #custom-pomodoro.paused { color: ${p.fgMuted}; }
        #custom-pomodoro.break {
          background: ${p.hues.orange};
          color: ${p.bgInset};
        }
      '';
    };
  };
}
