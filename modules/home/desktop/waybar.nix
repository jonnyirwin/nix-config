{ config, osConfig, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  font = config.jonny.theme.font;
  s = cfg.scripts;

  pomodoro = config.jonny.desktop.pomodoro;
  pomodoroBin = name: "${pomodoro.package}/bin/${name}";
in
{
  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;

      # Bound to sway-session.target rather than launched from sway's config.
      # This replaces waybar-supervisor.sh, which existed only to work around a
      # race with the old unit's `Requisite=graphical-session.target`: that
      # failed instantly if the target wasn't up yet when sway's exec fired.
      systemd = {
        enable = true;
        targets = [ "sway-session.target" ];
      };

      settings.mainBar = {
        layer = "top";
        position = "top";

        modules-left = [ "custom/pomodoro" "sway/workspaces" ];
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

        "sway/workspaces" = {
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
          font-family: "${font.family}", "Symbols Nerd Font Mono", "DejaVu Sans Mono", monospace;
          font-size: ${toString font.size}px;
          min-height: 0;
        }

        #waybar {
          background: ${p.mantle};
          color: ${p.text};
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
          background: ${p.surface0};
          color: ${p.overlay1};
          border-radius: 999px;
          padding: 0 10px;
          margin: 2px 3px;
          min-height: 24px;
          border: none;
          box-shadow: none;
          transition: color 120ms ease, background 120ms ease;
        }

        #workspaces button:hover {
          color: ${p.text};
          background: ${p.surface1};
        }

        #workspaces button.focused {
          color: ${p.crust};
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
          background: ${p.surface0};
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

        #clock { color: ${p.blue}; }

        #battery { color: ${p.green}; }
        #battery.charging { color: ${p.teal}; }
        #battery.warning:not(.charging) { color: ${p.yellow}; }
        #battery.critical:not(.charging) { color: ${p.red}; }

        #backlight { color: ${p.yellow}; }

        #pulseaudio,
        #custom-audio-output { color: ${p.sapphire}; }

        #cpu { color: ${p.green}; }
        #memory { color: ${p.teal}; }
        #custom-ip { color: ${p.sky}; }
        #custom-ip.internal { color: ${p.overlay1}; }

        #custom-idle-inhibitor { color: ${p.overlay2}; }

        #tray { margin-right: 8px; }

        #custom-music { color: ${p.accent}; }

        #custom-pomodoro { color: ${p.peach}; }
        #custom-pomodoro.running { color: ${p.green}; }
        #custom-pomodoro.paused { color: ${p.overlay1}; }
        #custom-pomodoro.break {
          background: ${p.peach};
          color: ${p.crust};
        }
      '';
    };
  };
}
