{ config, lib, pkgs, ... }:

# Desktop helper scripts, built as writeShellApplication derivations.
#
# Why not plain files in ~/.config/sway/scripts: writeShellApplication puts
# every dependency on the script's own PATH via runtimeInputs and runs
# shellcheck at build time. A missing tool becomes a build failure instead of a
# keybinding that silently does nothing.
#
# Reference them from sway/waybar with `lib.getExe`, never by path.
#
# Convention: a script that was *cancelled* — Escape out of its rofi, Escape
# out of slurp's region drag — exits non-zero, the same as rofi and slurp
# themselves do. Sway ignores the status of an `exec` binding, so this costs
# nothing there, but command-menu reads it to tell "you changed your mind"
# from "that is done", and so knows whether to stay open.

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;

  # The cheatsheet prints these rather than restating them; jonny.desktop.keys
  # is the same declaration the compositor binds. See modules/home/desktop/
  # actions.nix.
  k = cfg.keys;

  # A wallpaper source is named after both its fetcher script
  # (<name>-wallpaper) and its subdirectory of wallpaperDir, so the toggles in
  # jonny.desktop.wallpaper.sources are read through without a second table
  # mapping one to the other. See modules/home/desktop/wallpaper.nix.
  enabledSources = lib.attrNames (lib.filterAttrs (_: on: on) cfg.wallpaper.sources);
  disabledSources = lib.attrNames (lib.filterAttrs (_: on: !on) cfg.wallpaper.sources);

  wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";

  # Hex "#rrggbb" -> "r;g;b", for terminal 24-bit colour escapes.
  hexDigits = lib.listToAttrs (lib.imap0
    (i: c: lib.nameValuePair c i)
    (lib.stringToCharacters "0123456789abcdef"));

  hexToInt = s: lib.foldl'
    (acc: c: acc * 16 + hexDigits.${c})
    0
    (lib.stringToCharacters (lib.toLower s));

  rgbOf = hex:
    let
      h = lib.removePrefix "#" hex;
      component = offset: toString (hexToInt (builtins.substring offset 2 h));
    in
    "${component 0};${component 2};${component 4}";

  mkScript = name: { runtimeInputs ? [ ], text }:
    pkgs.writeShellApplication { inherit name runtimeInputs text; };

  scripts = lib.mapAttrs mkScript {
    # ---- Screen capture ----
    screenshot-region = {
      runtimeInputs = with pkgs; [ grim slurp wl-clipboard ];
      text = ''
        grim -g "$(slurp)" - | wl-copy
      '';
    };

    screenshot-annotate = {
      runtimeInputs = with pkgs; [ flameshot ];
      text = ''
        # Flameshot is Qt and predates Wayland; without these it either starts
        # on XWayland with a blank/stale capture or refuses to draw its overlay.
        # Theming needs nothing here: QT_QPA_PLATFORMTHEME now reaches sway's
        # environment via home.sessionVariables (see desktop/qt.nix), so the
        # toolbar picks up the palette like every other Qt app.
        export XDG_CURRENT_DESKTOP=sway
        export QT_QPA_PLATFORM=wayland

        exec flameshot gui --path ${lib.escapeShellArg "${config.home.homeDirectory}/Pictures/Screenshots"}
      '';
    };

    ocr-region = {
      runtimeInputs = with pkgs; [ grim slurp tesseract wl-clipboard libnotify coreutils ];
      text = ''
        region=$(slurp) || exit 1
        [ -n "$region" ] || exit 1

        text=$(grim -g "$region" - | tesseract - - 2>/dev/null)

        if [ -z "$text" ]; then
          notify-send "OCR" "No text detected"
          exit 1
        fi

        printf '%s' "$text" | wl-copy
        notify-send "OCR" "Copied $(printf '%s' "$text" | wc -w) words to clipboard"
      '';
    };

    # Same shape as ocr-region, one region and one decoder along: a QR code on
    # a slide, a phone screen or a poster becomes clipboard text without
    # reaching for a phone camera.
    qr-decode = {
      runtimeInputs = with pkgs; [ grim slurp zbar wl-clipboard libnotify coreutils ];
      text = ''
        region=$(slurp) || exit 1
        [ -n "$region" ] || exit 1

        # zbarimg's stdin handling depends on how it was built, so go via a
        # file — grim writes PNG either way and the trap cleans up.
        shot=$(mktemp --suffix=.png)
        trap 'rm -f "$shot"' EXIT
        grim -g "$region" "$shot"

        # zbarimg exits non-zero when it finds nothing, which is a normal
        # outcome here rather than a failure worth aborting on.
        decoded=$(zbarimg --quiet --raw "$shot" 2>/dev/null) || true

        if [ -z "$decoded" ]; then
          notify-send "QR" "No code found in that region"
          exit 1
        fi

        printf '%s' "$decoded" | wl-copy
        notify-send "QR" "Copied: $decoded"
      '';
    };

    color-picker = {
      runtimeInputs = with pkgs; [ grim slurp imagemagick wl-clipboard libnotify ];
      text = ''
        region=$(slurp -p) || exit 1
        [ -n "$region" ] || exit 1

        hex=$(grim -g "$region" -t png - | magick - -format '%[hex:p{0,0}]' info: 2>/dev/null)

        if [ -z "$hex" ]; then
          notify-send "Colour picker" "Failed to sample pixel"
          exit 1
        fi

        # ImageMagick may append alpha (RRGGBBAA); keep RRGGBB.
        hex=''${hex:0:6}
        printf '#%s' "$hex" | wl-copy
        notify-send "Colour picker" "#$hex copied to clipboard"
      '';
    };

    record-toggle = {
      runtimeInputs = with pkgs; [ wf-recorder slurp libnotify coreutils procps ];
      text = ''
        dir="$HOME/Videos/Recordings"
        pidfile="''${XDG_RUNTIME_DIR:-/tmp}/wf-recorder.pid"
        mkdir -p "$dir"

        if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
          pid=$(cat "$pidfile")
          # SIGINT rather than SIGTERM: wf-recorder finalises the container on INT.
          kill -INT "$pid"
          for _ in 1 2 3 4 5; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.2
          done
          rm -f "$pidfile"
          notify-send "Recording" "Stopped"
          exit 0
        fi

        region=$(slurp) || exit 1
        [ -n "$region" ] || exit 1

        filename="$dir/recording-$(date +%Y%m%d-%H%M%S).mp4"
        wf-recorder -g "$region" -f "$filename" &
        echo $! > "$pidfile"

        notify-send "Recording" "Started — press the binding again to stop"
      '';
    };

    # ---- Pickers and menus ----
    emoji-picker = {
      runtimeInputs = with pkgs; [ rofimoji rofi wtype wl-clipboard ];
      text = ''
        # `type` sends keystrokes to the focused window via wtype; `copy` also
        # stashes the emoji in the clipboard as a fallback.
        exec rofimoji --selector rofi --action type copy
      '';
    };

    window-switcher = {
      runtimeInputs = with pkgs; [ sway jq rofi ];
      text = ''
        selected=$(swaymsg -t get_tree \
          | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.pid? and .name?) | "\(.id)\t\(.app_id // .window_properties.class // "unknown")\t\(.name)"' \
          | rofi -dmenu -i -p "Window" -format 's')

        # Non-zero on an empty pick, i.e. Escape. See the convention at the
        # top of this file.
        [ -n "$selected" ] || exit 1

        swaymsg "[con_id=$(echo "$selected" | cut -f1)]" focus
      '';
    };

    # Rofi menu to rotate the focused output. Applies via `swaymsg output …
    # transform`; the same wl_output transform values also go in
    # jonny.desktop.outputs (for the permanent default) and the SDDM greeter's
    # weston config (modules/nixos/desktop/sddm.nix), so a rotation set here is
    # ephemeral — fold anything permanent back into those.
    screen-rotate = {
      runtimeInputs = with pkgs; [ sway jq rofi ];
      text = ''
        options=(
          "Landscape"
          "Portrait (right)"
          "Landscape (flipped)"
          "Portrait (left)"
        )

        choice=$(printf '%s\n' "''${options[@]}" \
          | rofi -dmenu -i -p "Rotate screen" -theme-str 'window {width: 300px;}')
        [ -n "$choice" ] || exit 1

        # "Landscape (flipped)" must be tested before the bare "Landscape" glob.
        case "$choice" in
          *"Landscape (flipped)"*) transform="180" ;;
          *"Portrait (right)"*)    transform="90" ;;
          *"Portrait (left)"*)     transform="270" ;;
          *Landscape*)             transform="normal" ;;
          *)                       exit 1 ;;
        esac

        # Rotate the focused output; fall back to the first active one.
        output=$(swaymsg -t get_outputs | jq -r 'map(select(.focused))[0].name // empty')
        if [ -z "$output" ]; then
          output=$(swaymsg -t get_outputs | jq -r 'map(select(.active))[0].name // empty')
        fi
        [ -n "$output" ] || exit 1

        swaymsg output "$output" transform "$transform"
      '';
    };

    power-menu = {
      runtimeInputs = with pkgs; [ rofi sway systemd scripts.lock-screen ];
      text = ''
        options=(
          "🔒 Lock"
          "🚪 Logout"
          "💤 Suspend"
          "🔄 Reboot"
          "⏻ Shutdown"
          "❌ Cancel"
        )

        chosen=$(printf '%s\n' "''${options[@]}" \
          | rofi -dmenu -i -p "Power Menu" -theme-str 'window {width: 300px;}')

        case "$chosen" in
          "🔒 Lock")     lock-screen ;;
          "🚪 Logout")   swaymsg exit ;;
          "💤 Suspend")  systemctl suspend ;;
          "🔄 Reboot")   systemctl reboot ;;
          "⏻ Shutdown") systemctl poweroff ;;
          # Cancel — the explicit entry, or Escape. Non-zero so a caller can
          # tell it apart from having actually done something.
          *)             exit 1 ;;
        esac
      '';
    };

    network-menu = {
      runtimeInputs = with pkgs; [ networkmanager networkmanagerapplet rofi coreutils libnotify ];
      text = ''
        # "enabled"/"disabled", never "on"/"off" — nmcli has no spelling of
        # this state that matches what this used to compare against. Every
        # branch below therefore took the wrong path at once: the icon was
        # always the struck-through glyph, the SSID list was never built, and
        # Toggle WiFi always fell through to `radio wifi on`, which is a no-op
        # on a machine whose radio was already enabled. The menu offered a
        # toggle that did nothing and no networks to pick from.
        #
        # The wired hosts never showed this. It took mac — the first host with
        # no ethernet and no saved wifi — for the menu's only two useful
        # behaviours to both be missing at the same time.
        wifi_status=$(nmcli -t radio wifi)

        # Not `[ ... ] && x=y`: under `set -e` a false test would abort the script.
        wifi_icon="󰤭"
        if [ "$wifi_status" = "enabled" ]; then wifi_icon="󰤨"; fi

        connected=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)

        options="$wifi_icon Toggle WiFi"

        if [ "$wifi_status" = "enabled" ]; then
          while IFS= read -r network; do
            [ -n "$network" ] || continue
            if [ "$network" = "$connected" ]; then
              options="$options"$'\n'"󰒓 $network (connected)"
            else
              options="$options"$'\n'"󰒕 $network"
            fi
          done < <(nmcli -t -f SSID device wifi list 2>/dev/null | sort -u)
        fi

        options="$options"$'\n'"Manage connections"

        choice=$(printf '%s' "$options" | rofi -dmenu -p "Network" -i)

        case "$choice" in
          "$wifi_icon Toggle WiFi")
            if [ "$wifi_status" = "enabled" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi
            ;;
          "Manage connections")
            # The real editor, not `nmcli connection show` piped into rofi.
            # That only ever *displayed* the list — picking a row did nothing —
            # so a profile holding a mistyped passphrase could be seen from
            # here but never corrected or forgotten. This is the thing that
            # makes "manage" mean something.
            exec nm-connection-editor
            ;;
          *"(connected)")
            network="''${choice% (connected)}"
            nmcli connection down "''${network#* }"
            ;;
          "󰒕"*)
            ssid="''${choice#* }"

            # No passphrase handling here, deliberately. nm-applet runs as a
            # NetworkManager secret agent (started from sway's startup block),
            # so NM prompts for the PSK itself — for this script and for every
            # other client, nmcli included.
            #
            # This used to prompt through rofi and hand the answer to nmcli.
            # That got the retry case wrong in a way that mattered: a profile
            # saved with a mistyped passphrase became a dead end, because the
            # prompt only appeared when *nothing* was saved, so every later
            # attempt silently reused the bad secret and failed identically.
            # The agent marks a rejected secret invalid and asks again, which
            # is the behaviour we want and not worth reimplementing badly.
            nmcli device wifi connect "$ssid" \
              || notify-send -u critical "Wi-Fi" "Could not connect to $ssid"
            ;;
          # Cancelled, or an empty pick. See the convention at the top.
          *) exit 1 ;;
        esac
      '';
    };

    # ---- Session ----
    lock-screen = {
      runtimeInputs = with pkgs; [ swaylock coreutils ];
      text = ''
        # Through wallpaper-pool, not a find of its own: the lock screen honours
        # jonny.desktop.wallpaper.sources like everything else, so switching a
        # collection off takes it off the lock screen too. Still a shuffle
        # rather than the picture currently on the desktop — the point of the
        # lock screen is that the desktop is not what you are looking at.
        wallpaper=$(${lib.getExe scripts.wallpaper-pool} | shuf -z -n 1 | tr -d '\0' || true)

        if [ -n "$wallpaper" ]; then
          exec swaylock -f --indicator-idle-visible -i "$wallpaper"
        fi

        # No wallpapers yet — swaylock still locks, using its configured colours.
        exec swaylock -f --indicator-idle-visible
      '';
    };

    # The one place that knows what is in the rotation. Sources switched off in
    # jonny.desktop.wallpaper.sources are pruned here — deleted from the walk,
    # never from the disk, so switching one back on restores its archive rather
    # than starting from an empty directory. Anything you put in the pool
    # yourself is untouched: only the sources' own directories are named.
    #
    # Both readers go through this rather than each running its own find: the
    # rotation below, and lock-screen. They had drifted once already — the lock
    # screen was still showing APOD pictures from a collection the desktop had
    # been told to stop using.
    #
    # NUL-delimited and sorted: a space in a filename is ordinary and a newline
    # is at least possible, and a stable order is the whole point of cycling
    # rather than shuffling.
    wallpaper-pool = {
      runtimeInputs = with pkgs; [ findutils coreutils ];
      text = ''
        dir="''${1:-${wallpaperDir}}"
        prune=( ${lib.concatMapStringsSep " " (name: ''-path "$dir/${name}" -prune -o'') disabledSources} )

        find "$dir" "''${prune[@]}" -type f \
          \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.jxl' \) \
          -print0 2>/dev/null | sort -z
      '';
    };

    # Walks the pool in filename order rather than picking at random. Random
    # meant the same picture twice in a row often enough to be irritating, and
    # no way to go back to the one you just skipped past.
    #
    #   wallpaper next     the binding, and the daily timer
    #   wallpaper prev     the one you just went past
    #   wallpaper current  re-apply without advancing, for sway's startup
    wallpaper = {
      runtimeInputs = with pkgs; [ findutils coreutils procps systemd imagemagick sway jq ];
      text = ''
        mode="''${1:-next}"
        dir="''${2:-${wallpaperDir}}"

        # Which picture is showing outlives the session, so a reboot carries on
        # through the pool rather than starting from the top every time.
        state="''${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
        mkdir -p "$(dirname "$state")"

        read_pool() {
          mapfile -d "" -t files < <(${lib.getExe scripts.wallpaper-pool} "$dir")
        }

        read_pool

        # An empty directory used to mean no wallpaper until the next timer
        # firing at 06:00 UTC — on a fresh install, or after the 30-day prune
        # has outrun a spell of downtime, that is a long time staring at
        # nothing. Fetch on the spot instead. `|| true` because this also runs
        # at login on machines that are offline then, where a failed fetch must
        # not take the whole script down with it under `set -e`.
        #
        # Only for the default directory: a fetcher writes into its own
        # subdirectory of wallpaperDir regardless of what was asked for here,
        # so bootstrapping an explicitly-passed directory would fetch a picture
        # that the re-read below could not see.
        if [ ''${#files[@]} -eq 0 ] && [ "$dir" = ${lib.escapeShellArg wallpaperDir} ]; then
          ${if enabledSources == [ ]
            then ": # every source is switched off; nothing to fetch"
            else lib.concatMapStringsSep "\n          "
              (name: "${lib.getExe scripts."${name}-wallpaper"} || true")
              enabledSources}
          read_pool
        fi

        # Still nothing; leave whatever swaybg is already doing alone.
        [ ''${#files[@]} -gt 0 ] || exit 0

        count=''${#files[@]}
        current=$(cat "$state" 2>/dev/null || true)

        # By path, not by a stored index: adding or deleting a file shifts
        # every index after it, and the pool changes under us daily.
        index=-1
        for i in "''${!files[@]}"; do
          if [ "''${files[$i]}" = "$current" ]; then
            index=$i
            break
          fi
        done

        if [ "$index" -lt 0 ]; then
          # Nothing showing yet, or the file that was went away.
          case "$mode" in
            prev) target=$((count - 1)) ;;
            *)    target=0 ;;
          esac
        else
          case "$mode" in
            current) target=$index ;;
            next)    target=$(( (index + 1) % count )) ;;
            prev)    target=$(( (index - 1 + count) % count )) ;;
            *)       echo "usage: wallpaper [next|prev|current] [dir]" >&2; exit 2 ;;
          esac
        fi

        pick="''${files[$target]}"
        printf '%s' "$pick" > "$state"

        # swaybg's `fill` scales until the image covers the output and crops
        # whatever hangs over. That is right when the two shapes roughly agree
        # and badly wrong when they do not: this panel is rotated into portrait,
        # so a 16:9 photograph filled onto it shows about a third of its width
        # — which is how a good picture ends up looking like a bad one.
        #
        # So: fill when the orientations agree, fit when they disagree, on a
        # background drawn from the palette so the bars read as framing rather
        # than as something having gone wrong. Either measurement failing just
        # falls back to the old behaviour.
        fit=fill
        read -r img_w img_h < <(identify -format '%w %h' "''${pick}[0]" 2>/dev/null) || true
        read -r out_w out_h < <(
          swaymsg -t get_outputs 2>/dev/null | jq -r '
            map(select(.active))[0]
            | if (.transform // "normal") | test("^(90|270)")
              then "\(.current_mode.height) \(.current_mode.width)"
              else "\(.current_mode.width) \(.current_mode.height)"
              end' 2>/dev/null
        ) || true

        if [ -n "''${img_w:-}" ] && [ -n "''${out_w:-}" ] && [ "''${out_w:-0}" -gt 0 ]; then
          img_landscape=$([ "$img_w" -ge "$img_h" ] && echo yes || echo no)
          out_landscape=$([ "$out_w" -ge "$out_h" ] && echo yes || echo no)
          if [ "$img_landscape" != "$out_landscape" ]; then fit=fit; fi
        fi

        # swaybg has to outlive whoever started it, and `swaybg & disown` does
        # not achieve that: disown clears the shell's job table but leaves the
        # process in the caller's cgroup. Started from the nasa-wallpaper
        # oneshot, the new swaybg therefore landed in that unit's cgroup, and
        # the default KillMode=control-group had systemd kill it the instant
        # the unit went inactive. The daily refresh reliably ended in a blank
        # screen that lasted until the next manual Mod+w — which worked only
        # because sway's exec puts swaybg in the long-lived session scope.
        #
        # A transient unit is owned by the user manager rather than by us, so
        # it survives its launcher no matter which of the callers (sway
        # startup, Mod+w, the menu, the timer) started it.
        #
        # An absolute path, not runtimeInputs: the command is executed by the
        # systemd user manager, which does not inherit this script's PATH.
        systemctl --user stop wallpaper.service 2>/dev/null || true

        # Not `pkill -x swaybg`: nixpkgs wraps the binary, so the running
        # process is named .swaybg-wrapped and an exact-name match never hits
        # it. Substring-matching the name leaked one live swaybg per run. Kept
        # after the stop above only to catch instances predating this unit.
        pkill swaybg || true

        # Forward the display explicitly rather than trusting the user manager
        # to have been populated. sway fires its startup execs in config order
        # without waiting, and home-manager appends its
        # dbus-update-activation-environment after every entry from
        # config.startup — so at first login this script runs while the
        # manager's environment is still empty, and a transient unit would
        # inherit no WAYLAND_DISPLAY and fail to connect. Our *own* environment
        # always has it, whichever of the callers we are.
        #
        # Not `[ -n ... ] && setenv+=(...)`: under `set -e` a false test on the
        # last command of the script would exit nonzero.
        setenv=()
        if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
          setenv+=("--setenv=WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
        fi
        if [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
          setenv+=("--setenv=XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR")
        fi

        systemd-run --user --quiet --collect --unit=wallpaper \
          "''${setenv[@]}" \
          ${lib.getExe pkgs.swaybg} -i "$pick" -m "$fit" -c ${lib.escapeShellArg (lib.removePrefix "#" p.bg)}
      '';
    };

    # Fetches only — applying it is the wallpaper.nix timer's job (chaining
    # this with random-wallpaper), so this script stays a plain producer that
    # both the desktop background and lock-screen pickers above pick up on
    # their own since it drops the image straight into wallpaperDir.
    # Bing's daily photograph. A better wallpaper source than APOD by some
    # distance: it is chosen as a picture rather than as astronomy, it needs no
    # API key, and `_UHD` is 3840x2160 every day rather than whatever the
    # telescope happened to produce.
    bing-wallpaper = {
      runtimeInputs = with pkgs; [ curl jq findutils coreutils ];
      text = ''
        dir=${lib.escapeShellArg "${wallpaperDir}/bing"}
        mkdir -p "$dir"

        # Eight days is as far back as the archive goes. Fetching the lot and
        # skipping what is already here means a machine that was off for a week
        # catches up instead of losing those days for good.
        json=$(curl -fsS 'https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=8&mkt=en-GB')

        printf '%s' "$json" \
          | jq -r '.images[] | "\(.enddate)\t\(.urlbase)"' \
          | while IFS=$'\t' read -r date urlbase; do
              dest="$dir/bing-$date.jpg"
              if [ -e "$dest" ]; then continue; fi

              # A partial download would otherwise sit there forever looking
              # like a file we already have.
              curl -fsSL "https://www.bing.com''${urlbase}_UHD.jpg" -o "$dest" || rm -f "$dest"
            done

        # Same month of history as the APOD directory, for the same reason.
        find "$dir" -type f -name 'bing-*.jpg' -mtime +30 -delete
      '';
    };

    nasa-wallpaper = {
      runtimeInputs = with pkgs; [ curl jq findutils coreutils imagemagick ];
      text = ''
        dir=${lib.escapeShellArg "${wallpaperDir}/nasa"}
        mkdir -p "$dir"

        api_key="''${NASA_API_KEY:-DEMO_KEY}"
        json=$(curl -fsS "https://api.nasa.gov/planetary/apod?api_key=$api_key")

        # Name the file after APOD's own date rather than the local one. The
        # two disagree either side of the rollover (midnight US Eastern), and
        # naming by local date filed one picture under two names — doubling
        # the directory and halving the rotation's variety.
        apod_date=$(printf '%s' "$json" | jq -r '.date')
        dest="$dir/apod-$apod_date.jpg"

        # Already have this one.
        [ -e "$dest" ] && exit 0

        media_type=$(printf '%s' "$json" | jq -r '.media_type')
        # Some days are videos rather than images — nothing to download.
        [ "$media_type" = "image" ] || exit 0

        url=$(printf '%s' "$json" | jq -r '.hdurl // .url')
        curl -fsSL "$url" -o "$dest"

        # APOD is an astronomy feed, not a wallpaper feed. Plenty of days are
        # diagrams or thousand-pixel crops that a panel this size can only
        # upscale into mush — nine of the twenty-two already downloaded are
        # below the floor below. Measure what arrived and throw away what will
        # not hold up, rather than leaving it to turn up in the rotation.
        #
        # By long and short edge rather than a single number in both: the
        # picture is scaled to the screen's long edge or its short one
        # depending on which way round the two are, so a 2048x1152 photograph
        # is perfectly good here and a flat 1400-in-both-directions floor
        # would have thrown it out along with the genuinely small ones.
        read -r width height < <(identify -format '%w %h' "''${dest}[0]" 2>/dev/null) || true
        long=''${width:-0}
        short=''${height:-0}
        if [ "$short" -gt "$long" ]; then
          long=''${height:-0}
          short=''${width:-0}
        fi

        if [ "$long" -lt 1920 ] || [ "$short" -lt 1080 ]; then
          rm -f "$dest"
          exit 0
        fi

        # APOD updates once a day; a month of history is plenty of rotation
        # variety without the directory growing forever.
        find "$dir" -type f -name 'apod-*.jpg' -mtime +30 -delete
      '';
    };

    clipboard-sync = {
      runtimeInputs = [ pkgs.wl-clipboard ];
      text = ''
        # Mirror the clipboard into the PRIMARY selection so middle-click paste
        # works from applications that only set CLIPBOARD.
        exec wl-paste -t text --watch wl-copy -p
      '';
    };

    scratchpad-toggle = {
      runtimeInputs = with pkgs; [ sway jq coreutils ];
      text = ''
        # scratchpad-toggle <app_id> <width> <height> <cmd...>
        app_id="$1"; w="$2"; h="$3"; shift 3

        present() {
          swaymsg -t get_tree | jq -e --arg id "$app_id" \
            'recurse(.nodes[]?, .floating_nodes[]?) | select(.app_id? == $id)' >/dev/null
        }

        reveal() {
          swaymsg "[app_id=\"$app_id\"] scratchpad show"
          swaymsg "[app_id=\"$app_id\"] resize set $w $h"
          swaymsg "[app_id=\"$app_id\"] move position center"
        }

        if present; then
          reveal
        else
          # Nothing pre-launches these, so the first press has to create the
          # window. The window rule parks it in the scratchpad the instant it
          # appears, which would leave this press showing nothing — so wait for
          # it and then summon it. Bounded, so a launch that never produces a
          # window gives up instead of spinning.
          "$@" &
          for _ in $(seq 50); do
            if present; then reveal; break; fi
            sleep 0.1
          done
        fi
      '';
    };

    # ---- Audio ----
    audio-output = {
      runtimeInputs = with pkgs; [ wireplumber gnugrep gnused ];
      text = ''
        # Icon for the current default sink, by name. Font Awesome codepoints.
        sink_line=$(wpctl status | grep -A3 "Sinks:" | grep "\*" || true)
        sink_name=$(printf '%s' "$sink_line" \
          | sed -E 's/.*[0-9]+\.[[:space:]]+(.+)[[:space:]]+\[vol.*/\1/' \
          | sed 's/[[:space:]]*$//')

        case "$sink_name" in
          *[Bb]luetooth*|*[Bb]luez*)   printf "" ;;  # bluetooth
          *HDMI*|*DisplayPort*|*GK107*) printf "" ;; # display
          *[Hh]eadphone*|*[Hh]eadset*) printf "" ;;  # headphones
          *USB*|*DAC*)                 printf "" ;;  # usb
          *)                           printf "" ;;  # speaker
        esac
        echo ""
      '';
    };

    audio-switch = {
      runtimeInputs = with pkgs; [ wireplumber rofi gnused libnotify coreutils ];
      text = ''
        sinks=$(wpctl status | sed -n '/├─ Sinks:/,/├─ Sources:/p' \
          | grep -E '[0-9]+\.' \
          | sed -E 's/.*[│*][[:space:]]+([0-9]+)\.[[:space:]]+(.+)[[:space:]]+\[vol.*/\1: \2/' \
          | sed 's/[[:space:]]*$//')

        selection=$(printf '%s\n' "$sinks" \
          | rofi -dmenu -i -p "Audio Output" -theme-str 'window {width: 400px;}')

        [ -n "$selection" ] || exit 1

        id=''${selection%%:*}
        name=''${selection#*: }
        wpctl set-default "$id"
        notify-send -t 2000 "Audio Output" "Switched to $name"
      '';
    };

    # ---- Display ----
    # brightnessctl only ever spoke to /sys/class/backlight, which exists on a
    # laptop panel and not on a desktop monitor — so on the desktops the
    # brightness keys did nothing and the adjustment lived on the monitor's own
    # buttons. External displays take the same instruction over DDC/CI on the
    # i2c bus behind the video cable; ddcutil speaks it. Needs the i2c group
    # and the i2c-dev module, both from modules/nixos/desktop/ddc.nix.
    brightness = {
      runtimeInputs = with pkgs; [ brightnessctl ddcutil gnused gawk libnotify coreutils procps util-linux ];
      text = ''
        case "''${1:-up}" in
          up)   sign="+"; delta=1 ;;
          down) sign="-"; delta=-1 ;;
          *)    echo "usage: brightness up|down [step]" >&2; exit 2 ;;
        esac
        # 10, not 5: a DDC round trip is slow enough that fine-grained steps
        # are no pleasure to hold down, and ten points is a visible change on
        # a single press.
        step=''${2:-10}

        # An internal panel is both the likelier target and the instant one, so
        # it wins when the machine has one. waybar's built-in backlight module
        # follows the sysfs device, so nothing needs telling.
        for panel in /sys/class/backlight/*; do
          if [ -e "$panel" ]; then
            brightnessctl set "''${step}%''${sign}" >/dev/null
            exit 0
          fi
        done

        run="''${XDG_RUNTIME_DIR:-/tmp}"
        buses="$run/ddc-buses"
        level="$run/ddc-brightness"
        pending="$run/ddc-brightness.pending"

        # `ddcutil detect` probes every i2c bus and takes the better part of a
        # second — far too slow for a key held down — so the buses are resolved
        # once per session. Delete the cache after plugging a monitor in.
        if [ ! -s "$buses" ]; then
          ddcutil detect --brief 2>/dev/null \
            | sed -n 's|.*/dev/i2c-\([0-9][0-9]*\).*|\1|p' > "$buses" || true
        fi

        if [ ! -s "$buses" ]; then
          notify-send "Brightness" "No internal panel, and no DDC/CI display responded"
          exit 1
        fi

        # A DDC round trip takes long enough that pressing the key twice starts
        # the second process before the first has finished. Each one used to
        # read the cached level, add its own step and write the result back, so
        # presses raced: two would read the same starting value and one would
        # overwrite the other, and because the writes landed out of order the
        # level wandered upward as readily as down however the key was held.
        #
        # Presses are queued as a signed number of points instead, and exactly
        # one process applies them. That fixes the race and collapses a flurry
        # of presses into a single write, which is also the only way holding
        # the key can keep up with a bus this slow.
        exec 9>"$run/ddc-brightness.queue.lock"
        exec 8>"$run/ddc-brightness.apply.lock"

        queue_add() {
          local queued
          flock 9
          queued=$(cat "$pending" 2>/dev/null || echo 0)
          printf '%s\n' "$((queued + $1))" > "$pending"
          flock -u 9
        }

        queue_take() {
          local queued
          flock 9
          queued=$(cat "$pending" 2>/dev/null || echo 0)
          printf '0\n' > "$pending"
          flock -u 9
          printf '%s' "$queued"
        }

        queue_add "$((delta * step))"

        # Losing this race is not a failure: whoever holds the lock re-reads the
        # queue after every write, so the step just added is already accounted
        # for and this press can simply leave.
        flock -n 8 || exit 0

        while true; do
          amount=$(queue_take)
          if [ "$amount" -eq 0 ]; then break; fi

          # Reading the level back over i2c is as slow as detection, so the
          # current value is cached and only the first press after a login pays
          # for the read. Setting an absolute value rather than stepping
          # relatively is what keeps that cache honest — and what lets the bar
          # show a number at all.
          if [ -s "$level" ]; then
            current=$(cat "$level")
          else
            current=$(ddcutil --bus "$(head -1 "$buses")" getvcp 10 --brief 2>/dev/null \
              | awk '{print $4}') || true
            [ -n "''${current:-}" ] || current=50
          fi

          new=$((current + amount))
          if [ "$new" -gt 100 ]; then new=100; fi
          if [ "$new" -lt 0 ]; then new=0; fi
          if [ "$new" -eq "$current" ]; then continue; fi

          # Verification (a read-back after the write) is left on deliberately,
          # at the cost of a second round trip. Plenty of monitors advertise
          # feature 10 in their capabilities and then quietly decline to act on
          # it — anything with an eco or dynamic-contrast mode engaged, for one
          # — and without the check the level cached below would drift away
          # from what the screen is actually doing, putting a number on the bar
          # that is simply untrue.
          took=0
          while read -r bus; do
            if ddcutil --bus "$bus" setvcp 10 "$new" >/dev/null 2>&1; then
              took=1
            fi
          done < "$buses"

          if [ "$took" = 0 ]; then
            notify-send "Brightness" "Display would not accept $new% over DDC/CI"
            exit 1
          fi

          printf '%s\n' "$new" > "$level"

          # Nudge the bar rather than making it poll a bus this slow.
          pkill -RTMIN+11 waybar || true
        done
      '';
    };

    # The bar's brightness pill, for displays that only answer over DDC/CI.
    # Silent — and so hidden, waybar drops a custom module whose text is empty
    # — on a machine with an internal panel, where the built-in backlight
    # module has it covered instead.
    brightness-status = {
      runtimeInputs = with pkgs; [ ddcutil gnused gawk coreutils ];
      text = ''
        for panel in /sys/class/backlight/*; do
          if [ -e "$panel" ]; then exit 0; fi
        done

        buses="''${XDG_RUNTIME_DIR:-/tmp}/ddc-buses"
        level="''${XDG_RUNTIME_DIR:-/tmp}/ddc-brightness"

        if [ ! -s "$buses" ]; then
          ddcutil detect --brief 2>/dev/null \
            | sed -n 's|.*/dev/i2c-\([0-9][0-9]*\).*|\1|p' > "$buses" || true
        fi

        # No DDC display either: this host has no brightness to show.
        [ -s "$buses" ] || exit 0

        if [ -s "$level" ]; then
          value=$(cat "$level")
        else
          value=$(ddcutil --bus "$(head -1 "$buses")" getvcp 10 --brief 2>/dev/null \
            | awk '{print $4}') || true
          [ -n "''${value:-}" ] || exit 0
          printf '%s\n' "$value" > "$level"
        fi

        printf '{"text":"%s","percentage":%s,"tooltip":"Brightness %s%%"}\n' \
          "$value" "$value" "$value"
      '';
    };

    # ---- Notifications ----
    # mako keeps dismissed notifications (max-history in desktop/mako.nix) and
    # `makoctl restore` puts the most recent one back on screen. This is the
    # "what did that say?" recovery for a toast that timed out while you were
    # looking at something else.
    notification-replay = {
      runtimeInputs = with pkgs; [ mako coreutils ];
      text = ''
        count=''${1:-1}
        for _ in $(seq 1 "$count"); do
          # Nothing left in history is the normal end of a replay, not a fault.
          makoctl restore || break
        done
      '';
    };

    # ---- Idle inhibitor ----
    # Holding a logind idle inhibitor is what actually stops the lock: swayidle
    # 1.9 reads the manager's BlockInhibited property and skips its timeout
    # commands while an --what=idle block lock is held. The lock lives for as
    # long as the `sleep infinity` child, so the pidfile is the whole state.
    idle-inhibitor-toggle = {
      runtimeInputs = with pkgs; [ systemd procps coreutils libnotify ];
      text = ''
        pidfile="''${XDG_RUNTIME_DIR:-/tmp}/idle-inhibitor.pid"

        if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
          kill "$(cat "$pidfile")"
          rm -f "$pidfile"
          notify-send -t 2000 "Idle inhibitor" "Off — screen locks after 5 min"
        else
          systemd-inhibit --what=idle --who="idle-inhibitor-toggle" \
            --why="Manual idle inhibitor" --mode=block sleep infinity &
          echo $! > "$pidfile"
          notify-send -t 2000 "Idle inhibitor" "On — screen will stay awake"
        fi

        # Refresh the waybar custom/idle-inhibitor module.
        pkill -RTMIN+10 waybar || true
      '';
    };

    # WARNING: the two `text` glyphs below are Nerd Font PUA codepoints
    # (nf-md-coffee, nf-md-sleep). Editors strip these silently — see the
    # warning at the top of waybar.nix. Re-inject the bytes, never retype them.
    idle-inhibitor-status = {
      runtimeInputs = with pkgs; [ coreutils procps jq ];
      text = ''
        pidfile="''${XDG_RUNTIME_DIR:-/tmp}/idle-inhibitor.pid"

        if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
          jq -c -n '{ text: "󰅶", tooltip: "Idle inhibited — the screen will not lock", class: "active" }'
        else
          jq -c -n '{ text: "󰒲", tooltip: "Idle timers running — the screen locks after 5 min", class: "inactive" }'
        fi
      '';
    };

    # ---- Reference ----
    cheatsheet = {
      runtimeInputs = with pkgs; [ less ];
      text =
        let
          accent = rgbOf p.accent;
          blue = rgbOf p.info;
          lavender = rgbOf p.borderActive;
          subtext = rgbOf p.fgSubtle;
          text' = rgbOf p.fg;
          surface = rgbOf p.surfaceActive;
        in
        ''
          RESET='\033[0m'
          BOLD='\033[1m'
          ACCENT='\033[38;2;${accent}m'
          BLUE='\033[38;2;${blue}m'
          LAVENDER='\033[38;2;${lavender}m'
          SUBTEXT='\033[38;2;${subtext}m'
          TEXT='\033[38;2;${text'}m'
          SURFACE='\033[38;2;${surface}m'

          # %b (not %s) for the colour variables: they hold literal \033[…
          # escapes that need interpreting. Keeping them out of the format
          # string itself is what satisfies shellcheck's SC2059.
          # 24, not 22: the composite rows now spell both keys out in full
          # ("Mod+Alt+K / Mod+Alt+J") rather than abbreviating the second.
          key()    { printf '  %b%b%-24s%b' "$LAVENDER" "$BOLD" "$1" "$RESET"; }
          desc()   { printf '%b%s%b\n' "$TEXT" "$1" "$RESET"; }
          sep()    { printf '%b  %-40s%b\n' "$SURFACE" "$(printf '─%.0s' {1..44})" "$RESET"; }
          header() { printf '\n%b%b  %s%b\n' "$ACCENT" "$BOLD" "$1" "$RESET"; sep; }

          {
          printf '%b%b  Sway Keybindings%b  %b(Mod = Super)%b\n' "$BLUE" "$BOLD" "$RESET" "$SUBTEXT" "$RESET"

          header "Basics"
          key '${k.terminal}'      ; desc "Terminal"
          key '${k.kill}'     ; desc "Kill window"
          key '${k.launcher}'           ; desc "App launcher"
          key '${k.windowSwitcher}'         ; desc "Window switcher"
          key '${k.clipboardHistory}'           ; desc "Clipboard history"
          key '${k.voiceInput}'           ; desc "Voice input toggle"
          key '${k.pastePrimary}'     ; desc "Paste PRIMARY selection"
          key '${k.reload}'     ; desc "Reload config"
          key '${k.powerMenu}'     ; desc "Power menu"
          key '${k.networkMenu}'     ; desc "Network menu"
          key '${k.lockScreen}'     ; desc "Lock screen"
          key '${k.idleInhibitor}'           ; desc "Idle inhibitor toggle"
          key '${k.toggleBar}'           ; desc "Toggle waybar"

          header "Apps & Scripts"
          key '${k.pomodoro}'           ; desc "Pomodoro timer"
          key '${k.emojiPicker}'           ; desc "Emoji picker"
          key '${k.ocrRegion}'     ; desc "OCR region → clipboard"
          key '${k.colorPicker}'     ; desc "Colour picker → clipboard"
          key '${k.screenshotRegion}'           ; desc "Screenshot region → clipboard"
          key '${k.screenshotAnnotate}'     ; desc "Screenshot (flameshot + annotations)"
          key '${k.recordToggle}'     ; desc "Toggle screen recording"
          key '${k.displayLayout}'     ; desc "Display layout (wdisplays)"
          key '${k.screenRotate}'      ; desc "Rotate screen (rofi menu)"
          key '${k.wallpaper}'           ; desc "Next wallpaper"
          key '${k.qrDecode}'     ; desc "Scan QR code → clipboard"
          key '${k.notificationReplay}'     ; desc "Replay last notification"
          key '${k.commandMenu}'  ; desc "Command menu (everything, nested)"

          header "Scratchpads"
          key '${k.scratchpadMixer}'           ; desc "Pulsemixer (audio mixer)"
          key '${k.scratchpadBtop}'           ; desc "btop (system monitor)"
          key '${k.scratchpadNotes}'           ; desc "Scratch notes"
          key '${k.scratchpadYazi}'           ; desc "Yazi (file manager)"
          key '${k.scratchpadCheatsheet}'           ; desc "This cheatsheet"
          key '${k.scratchpadShow}'           ; desc "Cycle scratchpad windows"
          key '${k.scratchpadMove}'     ; desc "Send window to scratchpad"

          header "Audio"
          key '${k.volumeUp} / ${k.volumeDown}'   ; desc "Volume up / down"
          key '${k.volumeMute}'       ; desc "Mute toggle"
          key '${k.mediaNext}'       ; desc "Next track"
          key '${k.mediaPrevious}'       ; desc "Previous track"
          key '${k.mediaPlayPause}'   ; desc "Play / pause"

          header "Brightness"
          key '${k.brightnessUp} / ${k.brightnessDown}'   ; desc "Brightness up / down"

          header "Focus"
          key "Mod+H/J/K/L"     ; desc "Focus left / down / up / right"
          key "Mod+Arrows"      ; desc "Focus (arrow keys)"
          key '${k.focusParent}'           ; desc "Focus parent container"
          key '${k.focusChild}'      ; desc "Focus child container"
          key '${k.focusModeToggle}'       ; desc "Toggle focus: tiling ↔ floating"

          header "Move Windows"
          key "Mod+Shift+H/J/K/L" ; desc "Move window"
          key "Mod+Ctrl+Arrows" ; desc "Move workspace to output"

          header "Workspaces"
          key "Mod+1–0"         ; desc "Switch to workspace"
          key "Mod+Shift+1–0"   ; desc "Move window to workspace"
          key '${k.workspaceBackAndForth}'          ; desc "Back and forth"

          header "Layout"
          key '${k.fullscreen}'           ; desc "Fullscreen"
          key '${k.floatingToggle}' ; desc "Toggle floating"
          key '${k.splitHorizontal}'           ; desc "Split horizontal"
          key '${k.splitVertical}'           ; desc "Split vertical"
          key '${k.toggleSplit}'           ; desc "Toggle split"
          key '${k.resizeMode}'           ; desc "Resize mode  (then H/J/K/L or arrows)"

          printf '\n%b  Q to close%b\n\n' "$SUBTEXT" "$RESET"
          } | less -R
        '';
    };
  };
in
{
  options.jonny.desktop.scripts = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    readOnly = true;
    default = scripts;
    description = "Desktop helper scripts, referenced by sway and waybar via lib.getExe.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.attrValues scripts;
  };
}
