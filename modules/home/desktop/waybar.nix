# WARNING: This file contains Nerd Font glyphs (Private Use Area codepoints,
# e.g. the volume, backlight and battery format-icons). Many editors and tools
# SILENTLY STRIP these on a typed edit, leaving an empty "" or a bare space
# where the icon was — waybar then renders with missing icons. This has
# happened repeatedly. If you touch a glyph, re-inject the raw UTF-8 bytes
# (e.g. `perl -CSD -i -pe 's/.../"\x{F057E}"/e'`), never retype them by hand.
{ config, osConfig, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  fonts = config.jonny.theme.fonts;
  s = cfg.scripts;

  pomodoro = config.jonny.desktop.pomodoro;
  pomodoroBin = name: "${pomodoro.package}/bin/${name}";

  backup = config.jonny.backup;

  # Waybar names its workspace widget after the compositor. Deriving it here is
  # the only compositor-specific thing left in this file.
  workspaceModule = "${cfg.compositor}/workspaces";

  # Icon coverage is declared once in jonny.theme.fonts.fallback rather than
  # being spelled out in this CSS.
  fontStack = lib.concatMapStringsSep ", " (f: ''"${f}"'')
    ([ fonts.ui.family ] ++ fonts.fallback) + ", monospace";

  # Shared by the built-in backlight module and the DDC/CI one below, so a
  # host shows the same three glyphs whichever of them it ends up using.
  # Copied bytes, never retyped: these are Private Use Area codepoints.
  brightnessIcons = [ "" "" "" ];
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
          "custom/backup"
          "network"
          "custom/audio-output"
          "pulseaudio"
          "backlight"
          "custom/brightness"
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
          format-icons = brightnessIcons;
          on-scroll-up = "${lib.getExe pkgs.brightnessctl} set 1%+";
          on-scroll-down = "${lib.getExe pkgs.brightnessctl} set 1%-";
        };

        # Brightness for a display that only answers over DDC/CI, which is
        # every monitor that is not a laptop panel. The built-in `backlight`
        # module above reads /sys/class/backlight and finds nothing on those
        # hosts, so it stays blank and this one fills in â and on a laptop the
        # positions are reversed, because brightness-status prints nothing when
        # there is an internal panel and waybar hides a custom module whose
        # text is empty.
        #
        # `once`, not an interval: reading a level back over i2c takes the
        # better part of a second, so the script keeps a cached value and the
        # `brightness` script raises RTMIN+11 after changing it.
        "custom/brightness" = {
          format = "{icon} {percentage:>3}%";
          format-icons = brightnessIcons;
          return-type = "json";
          interval = "once";
          signal = 11;
          exec = lib.getExe s.brightness-status;
          # No explicit step: the wheel moves in the same increments the keys
          # do, so brightness means one thing whichever way you reach for it.
          on-scroll-up = "${lib.getExe s.brightness} up";
          on-scroll-down = "${lib.getExe s.brightness} down";
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

        # Until this existed, wireless had no presence on the bar at all and the
        # only way in was the Mod+Shift+n rofi menu — which is fine once you
        # know it, and invisible until you do. Clicking the pill opens that same
        # menu rather than a second implementation of it.
        #
        # The module updates on netlink events; the interval is only so
        # signalStrength keeps moving while associated.
        network = {
          interval = 5;
          format-wifi = "󰤨 {signalStrength:>3}%";
          format-ethernet = "󰈀 {ipaddr}";
          format-disconnected = "󰤭";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          tooltip-format-wifi = "{essid}  {signalStrength}%\n{ipaddr}/{cidr}";
          tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}";
          tooltip-format-disconnected = "Disconnected";
          on-click = lib.getExe s.network-menu;
        };

        "custom/audio-output" = {
          format = "{}";
          interval = 2;
          exec = lib.getExe s.audio-output;
          on-click = lib.getExe s.audio-switch;
        };

        pulseaudio = {
          format = "{icon} {volume:>3}%";
          format-muted = "󰸈 ---%";
          format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
          on-click = lib.getExe pkgs.pavucontrol;
          on-click-right = lib.getExe s.audio-switch;
        };

        # Caffeine pill. State changes only when the toggle runs, so this polls
        # once at startup and thereafter refreshes on RTMIN+10, which
        # idle-inhibitor-toggle raises.
        "custom/idle-inhibitor" = {
          format = "{}";
          return-type = "json";
          interval = "once";
          signal = 10;
          exec = lib.getExe s.idle-inhibitor-status;
          on-click = lib.getExe s.idle-inhibitor-toggle;
        };

        "custom/backup" = lib.mkIf backup.enable {
          format = "{}";
          return-type = "json";
          # While a backup runs this reads rclone's remote-control API; when
          # idle it reports the age of the last success, so a backup that
          # silently stopped happening is visible rather than assumed.
          interval = 5;
          exec = lib.getExe backup.packages.status;
          on-click = "${lib.getExe pkgs.kitty} --class=float-backup ${lib.getExe backup.packages.now}";
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
        #custom-brightness,
        #clock,
        #battery,
        #cpu,
        #memory,
        #custom-ip,
        #network,
        #pulseaudio,
        #custom-audio-output,
        #custom-backup,
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

        #backlight,
        #custom-brightness { color: ${p.warning}; }

        #pulseaudio,
        #custom-audio-output { color: ${p.hues.blue}; }

        #cpu { color: ${p.success}; }
        #memory { color: ${p.hues.cyan}; }
        #custom-ip { color: ${p.hues.cyan}; }
        #custom-ip.internal { color: ${p.fgMuted}; }

        /* Muted rather than red when disconnected: on mac that is the normal
           resting state after a cold boot, not a fault worth alarming about. */
        #network { color: ${p.hues.cyan}; }
        #network.disconnected { color: ${p.fgMuted}; }

        /* Muted while idle timers run — it only earns attention when the
           screen has been deliberately pinned awake. */
        #custom-idle-inhibitor { color: ${p.fgMuted}; }
        #custom-idle-inhibitor.active {
          background: ${p.warning};
          color: ${p.bgInset};
        }

        /* Backup: muted when idle and recent, so it reads as "nothing to see".
           Only the states that want attention are coloured. */
        #custom-backup { color: ${p.fgMuted}; }
        #custom-backup.running { color: ${p.info}; }
        #custom-backup.stale { color: ${p.warning}; }
        #custom-backup.never {
          background: ${p.error};
          color: ${p.bgInset};
        }

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
