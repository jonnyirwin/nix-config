{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  s = cfg.scripts;
  k = cfg.keys;

  # One row of the menu: the label, and the key that does the same thing
  # without going through here. Quoting is done in Nix so the shell below stays
  # a list of labels rather than a thicket of quotes.
  row = label: key: "row ${lib.escapeShellArg label} ${lib.escapeShellArg key}";
  plainRow = label: "row ${lib.escapeShellArg label}";

  # Only the sources that are switched on, so the menu entry cannot quietly
  # fetch a collection the rotation will then prune back out.
  enabledSources = lib.attrNames (lib.filterAttrs (_: on: on) cfg.wallpaper.sources);

  scratchpad = sp:
    "${lib.getExe s.scratchpad-toggle} ${sp.id} ${toString sp.width} ${toString sp.height} ${sp.command}";
in
{
  # Omarchy 4's one idea worth borrowing wholesale: a single entry point that
  # nests every desktop command, instead of a keybinding per action and a
  # cheatsheet to remember them by.
  #
  # Deliberately additive. Every binding this fronts still works on its own
  # key, and the launcher, power menu and network menu are untouched — this is
  # a second door on the same rooms, kept separate so it can be dropped by
  # deleting one keybinding if it does not earn its place.
  #
  # Its own module rather than another entry in scripts.nix: it is the one
  # script that reads jonny.desktop.scratchpads, and scratchpads are built from
  # jonny.desktop.scripts, so living in that attrset would be a cycle.
  options.jonny.desktop.commandMenu = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = "The nested command menu, bound by the compositor config.";
    default = pkgs.writeShellApplication {
      name = "command-menu";
      runtimeInputs = with pkgs; [ rofi cliphist wl-clipboard wdisplays coreutils gnused ];
      text = ''
        # Rows carry the action's own keybinding, dimmed, so the menu teaches
        # its way out of itself: use it a few times and you know the key. The
        # keys are read from jonny.desktop.keys, the same declaration the
        # compositor binds, so they cannot drift from what the key does.
        DIM="${p.fgSubtle}"

        # Padded to a column so the shortcuts line up — the UI font is a
        # monospace, and pango keeps runs of spaces as written.
        row() {
          if [ -n "''${2:-}" ]; then
            printf '%-26s<span foreground="%s">%s</span>\n' "$1" "$DIM" "$2"
          else
            printf '%s\n' "$1"
          fi
        }

        # -markup-rows to render the span; -no-custom because every entry is a
        # known command, so a typo should filter to nothing rather than run
        # itself. The markup and the shortcut are display only: what comes back
        # is the bare label, which is what the case arms below match on.
        pick() {
          local choice
          choice=$(rofi -dmenu -i -no-custom -markup-rows -p "$1" \
            -theme-str 'window {width: 520px;}') || return 1
          # Everything from the first '<' is the shortcut column — the span
          # tags and the key inside them — so cut there rather than unwrapping
          # the markup, which would leave the key text stuck to the label.
          printf '%s' "$choice" | sed 's/<.*//; s/[[:space:]]*$//'
        }

        # Run a leaf action. Completing it closes the menu; a non-zero exit
        # means the action was cancelled — Escape out of its rofi, or out of
        # slurp's region drag — and that should leave you on the menu you came
        # from rather than taking the whole thing down with it. `exec` cannot
        # do this: it replaces the menu, so there is nothing to come back to.
        #
        # This is what the "cancelled is non-zero" convention at the top of
        # scripts.nix buys.
        run() {
          if "$@"; then exit 0; fi
          return 0
        }

        # A pipeline, so it needs a function to be passed to `run` as one unit.
        clipboard_paste() {
          local entry
          entry=$(cliphist list | rofi -dmenu -i -p Clipboard) || return 1
          printf '%s' "$entry" | cliphist decode | wl-copy
        }

        # Every submenu owns its loop, which is what makes Escape mean "up one
        # level" everywhere rather than "quit": returning from one of these
        # lands back in the outer loop and redraws the top menu, and only the
        # outer loop's own catch-all exits. "Back" is the same door with a
        # label on it, for when the mouse is already in the list.
        capture_menu() {
          while true; do
            case "$( { ${row "Screenshot to clipboard" k.screenshotRegion}
                       ${row "Screenshot and annotate" k.screenshotAnnotate}
                       ${row "Toggle screen recording" k.recordToggle}
                       ${row "OCR region" k.ocrRegion}
                       ${row "Scan QR code" k.qrDecode}
                       ${row "Pick colour" k.colorPicker}
                       ${row "Emoji" k.emojiPicker}
                       ${plainRow "Back"}; } | pick Capture)" in
              'Screenshot to clipboard')  run ${lib.getExe s.screenshot-region} ;;
              'Screenshot and annotate')  run ${lib.getExe s.screenshot-annotate} ;;
              'Toggle screen recording')  run ${lib.getExe s.record-toggle} ;;
              'OCR region')               run ${lib.getExe s.ocr-region} ;;
              'Scan QR code')             run ${lib.getExe s.qr-decode} ;;
              'Pick colour')              run ${lib.getExe s.color-picker} ;;
              Emoji)                      run ${lib.getExe s.emoji-picker} ;;
              *)                          return 0 ;;
            esac
          done
        }

        audio_menu() {
          while true; do
            case "$( { ${plainRow "Output device"}
                       ${row "Mixer" cfg.scratchpads.mixer.key}
                       ${plainRow "Back"}; } | pick Audio)" in
              'Output device') run ${lib.getExe s.audio-switch} ;;
              # The same pulsemixer scratchpad the key summons, not a second
              # mixer of its own: one window, wherever you ask for it from.
              Mixer)           exec ${scratchpad cfg.scratchpads.mixer} ;;
              *)               return 0 ;;
            esac
          done
        }

        display_menu() {
          while true; do
            case "$( { ${row "Arrange outputs" k.displayLayout}
                       ${row "Rotate output" k.screenRotate}
                       ${row "Brightness up" k.brightnessUp}
                       ${row "Brightness down" k.brightnessDown}
                       ${plainRow "Back"}; } | pick Display)" in
              # wdisplays is a window, not a picker: there is no cancelling
              # back out of it, so hand the session over and go.
              'Arrange outputs')  exec wdisplays ;;
              'Rotate output')    run ${lib.getExe s.screen-rotate} ;;
              # Not `run`: brightness is the one thing here you want to repeat,
              # so a successful step redraws this menu instead of closing it.
              'Brightness up')    ${lib.getExe s.brightness} up || true ;;
              'Brightness down')  ${lib.getExe s.brightness} down || true ;;
              *)                  return 0 ;;
            esac
          done
        }

        notifications_menu() {
          while true; do
            case "$( { ${row "Replay last" k.notificationReplay}
                       ${plainRow "Replay last ten"}
                       ${plainRow "Back"}; } | pick Notifications)" in
              'Replay last')      run ${lib.getExe s.notification-replay} ;;
              'Replay last ten')  run ${lib.getExe s.notification-replay} 10 ;;
              *)                  return 0 ;;
            esac
          done
        }

        wallpaper_menu() {
          while true; do
            case "$( { ${row "Next" k.wallpaper}
                       ${plainRow "Previous"}
                       ${plainRow "Fetch today's pictures"}
                       ${plainRow "Back"}; } | pick Wallpaper)" in
              # Stepping the rotation leaves the menu open, the way brightness
              # does: finding a picture you like means trying a few.
              Next)      ${lib.getExe s.wallpaper} next || true ;;
              Previous)  ${lib.getExe s.wallpaper} prev || true ;;
              "Fetch today's pictures")
                ${lib.concatMapStringsSep "\n                "
                  (name: "${lib.getExe s."${name}-wallpaper"} || true")
                  enabledSources}
                run ${lib.getExe s.wallpaper} next
                ;;
              *)         return 0 ;;
            esac
          done
        }

        power_menu() {
          while true; do
            case "$( { ${row "Power menu" k.powerMenu}
                       ${row "Lock screen" k.lockScreen}
                       ${row "Idle inhibitor" k.idleInhibitor}
                       ${plainRow "Back"}; } | pick Power)" in
              'Power menu')      run ${lib.getExe s.power-menu} ;;
              'Lock screen')     run ${lib.getExe s.lock-screen} ;;
              'Idle inhibitor')  run ${lib.getExe s.idle-inhibitor-toggle} ;;
              *)                 return 0 ;;
            esac
          done
        }

        # The outer loop. Escape here is the only one that ends the menu. The
        # categories carry no shortcut because there is no single key for them
        # — the keys live on the actions inside.
        while true; do
          case "$( { ${row "Apps" k.launcher}
                     ${row "Windows" k.windowSwitcher}
                     ${row "Clipboard" k.clipboardHistory}
                     ${plainRow "Capture"}
                     ${plainRow "Audio"}
                     ${plainRow "Display"}
                     ${row "Network" k.networkMenu}
                     ${plainRow "Notifications"}
                     ${plainRow "Wallpaper"}
                     ${plainRow "Power"}; } | pick Command)" in

            Apps)          run rofi -show drun -show-icons ;;
            Windows)       run ${lib.getExe s.window-switcher} ;;
            Clipboard)     run clipboard_paste ;;
            Network)       run ${lib.getExe s.network-menu} ;;

            Capture)       capture_menu ;;
            Audio)         audio_menu ;;
            Display)       display_menu ;;
            Notifications) notifications_menu ;;
            Wallpaper)     wallpaper_menu ;;
            Power)         power_menu ;;

            *)             exit 0 ;;
          esac
        done
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.commandMenu ];
  };
}
