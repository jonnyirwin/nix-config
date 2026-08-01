{ config, lib, pkgs, ... }:

# Desktop helper scripts, built as writeShellApplication derivations.
#
# Why not plain files in ~/.config/sway/scripts: writeShellApplication puts
# every dependency on the script's own PATH via runtimeInputs and runs
# shellcheck at build time. A missing tool becomes a build failure instead of a
# keybinding that silently does nothing.
#
# Reference them from sway/waybar with `lib.getExe`, never by path.

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;

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

        if [ -n "$selected" ]; then
          swaymsg "[con_id=$(echo "$selected" | cut -f1)]" focus
        fi
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
        [ -n "$choice" ] || exit 0

        # "Landscape (flipped)" must be tested before the bare "Landscape" glob.
        case "$choice" in
          *"Landscape (flipped)"*) transform="180" ;;
          *"Portrait (right)"*)    transform="90" ;;
          *"Portrait (left)"*)     transform="270" ;;
          *Landscape*)             transform="normal" ;;
          *)                       exit 0 ;;
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
          *)             exit 0 ;;
        esac
      '';
    };

    network-menu = {
      runtimeInputs = with pkgs; [ networkmanager rofi coreutils gnugrep libnotify ];
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
            nmcli connection show | rofi -dmenu -p "Connections" || true
            ;;
          *"(connected)")
            network="''${choice% (connected)}"
            nmcli connection down "''${network#* }"
            ;;
          "󰒕"*)
            ssid="''${choice#* }"

            # Nothing in this session runs a NetworkManager secret agent —
            # there is no nm-applet and no polkit agent — so for a network
            # with no stored secrets a bare `nmcli device wifi connect` has no
            # way to be handed the passphrase. It fails, and because nothing
            # here surfaced the error it looked exactly like the menu doing
            # nothing. Prompt for it ourselves instead, in the same rofi the
            # rest of this script already uses.
            #
            # Only when there is nothing saved: an existing connection profile
            # carries its own secrets, and re-prompting for a network that
            # already works would be worse than useless.
            if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
              nmcli connection up "$ssid" \
                || notify-send -u critical "Wi-Fi" "Could not connect to $ssid"
            else
              pass=$(rofi -dmenu -password -p "Passphrase for $ssid" < /dev/null || true)
              if [ -n "$pass" ]; then
                nmcli device wifi connect "$ssid" password "$pass" \
                  || notify-send -u critical "Wi-Fi" "Could not connect to $ssid"
              else
                # Empty passphrase: an open network, or the prompt was
                # dismissed. Try unauthenticated rather than assuming either.
                nmcli device wifi connect "$ssid" \
                  || notify-send -u critical "Wi-Fi" "Could not connect to $ssid"
              fi
            fi
            ;;
          *) exit 0 ;;
        esac
      '';
    };

    # ---- Session ----
    lock-screen = {
      runtimeInputs = with pkgs; [ swaylock findutils coreutils ];
      text = ''
        wallpaper=$(find ${lib.escapeShellArg wallpaperDir} -type f \
          \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null \
          | shuf -n 1 || true)

        if [ -n "$wallpaper" ]; then
          exec swaylock -f --indicator-idle-visible -i "$wallpaper"
        fi

        # No wallpapers yet — swaylock still locks, using its configured colours.
        exec swaylock -f --indicator-idle-visible
      '';
    };

    random-wallpaper = {
      runtimeInputs = with pkgs; [ findutils coreutils procps systemd ];
      text = ''
        dir="''${1:-${wallpaperDir}}"

        pick_one() {
          find "$dir" -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.jxl' \) -print0 2>/dev/null \
            | shuf -z -n 1 | tr -d '\0' || true
        }

        pick=$(pick_one)

        # An empty directory used to mean no wallpaper until the next timer
        # firing at 06:00 UTC — on a fresh install, or after the 30-day prune
        # has outrun a spell of downtime, that is a long time staring at
        # nothing. Fetch on the spot instead. `|| true` because this also runs
        # at login on machines that are offline then, where a failed fetch must
        # not take the whole script down with it under `set -e`.
        #
        # Only for the default directory: nasa-wallpaper writes into
        # wallpaperDir/nasa regardless of what was asked for here, so
        # bootstrapping an explicitly-passed directory would fetch a picture
        # that the re-pick below could not see.
        if [ -z "$pick" ] && [ "$dir" = ${lib.escapeShellArg wallpaperDir} ]; then
          ${lib.getExe scripts.nasa-wallpaper} || true
          pick=$(pick_one)
        fi

        # Still nothing; leave whatever swaybg is already doing alone.
        [ -n "$pick" ] || exit 0

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
        # it survives its launcher no matter which of the three callers
        # (sway startup, Mod+w, the timer) started it.
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
        # always has it, whichever of the three callers we are.
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
          ${lib.getExe pkgs.swaybg} -i "$pick" -m fill
      '';
    };

    # Fetches only — applying it is the wallpaper.nix timer's job (chaining
    # this with random-wallpaper), so this script stays a plain producer that
    # both the desktop background and lock-screen pickers above pick up on
    # their own since it drops the image straight into wallpaperDir.
    nasa-wallpaper = {
      runtimeInputs = with pkgs; [ curl jq findutils coreutils ];
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
      runtimeInputs = with pkgs; [ sway jq ];
      text = ''
        # scratchpad-toggle <app_id> <width> <height> <cmd...>
        app_id="$1"; w="$2"; h="$3"; shift 3

        if swaymsg -t get_tree | jq -e --arg id "$app_id" \
             'recurse(.nodes[]?, .floating_nodes[]?) | select(.app_id? == $id)' >/dev/null; then
          swaymsg "[app_id=\"$app_id\"] scratchpad show"
          swaymsg "[app_id=\"$app_id\"] resize set $w $h"
          swaymsg "[app_id=\"$app_id\"] move position center"
        else
          exec "$@"
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

        [ -n "$selection" ] || exit 0

        id=''${selection%%:*}
        name=''${selection#*: }
        wpctl set-default "$id"
        notify-send -t 2000 "Audio Output" "Switched to $name"
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
          key()    { printf '  %b%b%-22s%b' "$LAVENDER" "$BOLD" "$1" "$RESET"; }
          desc()   { printf '%b%s%b\n' "$TEXT" "$1" "$RESET"; }
          sep()    { printf '%b  %-40s%b\n' "$SURFACE" "$(printf '─%.0s' {1..44})" "$RESET"; }
          header() { printf '\n%b%b  %s%b\n' "$ACCENT" "$BOLD" "$1" "$RESET"; sep; }

          {
          printf '%b%b  Sway Keybindings%b  %b(Mod = Super)%b\n' "$BLUE" "$BOLD" "$RESET" "$SUBTEXT" "$RESET"

          header "Basics"
          key "Mod+Return"      ; desc "Terminal"
          key "Mod+Shift+Q"     ; desc "Kill window"
          key "Mod+D"           ; desc "App launcher"
          key "Mod+Tab"         ; desc "Window switcher"
          key "Mod+C"           ; desc "Clipboard history"
          key "Mod+;"           ; desc "Voice input toggle"
          key "Mod+Shift+V"     ; desc "Paste PRIMARY selection"
          key "Mod+Shift+C"     ; desc "Reload config"
          key "Mod+Shift+E"     ; desc "Power menu"
          key "Mod+Shift+X"     ; desc "Lock screen"
          key "Mod+I"           ; desc "Idle inhibitor toggle"
          key "Mod+O"           ; desc "Toggle waybar"

          header "Apps & Scripts"
          key "Mod+P"           ; desc "Pomodoro timer"
          key "Mod+="           ; desc "Font size scaling"
          key "Mod+."           ; desc "Emoji picker"
          key "Mod+Shift+O"     ; desc "OCR region → clipboard"
          key "Mod+Shift+P"     ; desc "Colour picker → clipboard"
          key "Mod+S"           ; desc "Screenshot region → clipboard"
          key "Mod+Shift+S"     ; desc "Screenshot (flameshot + annotations)"
          key "Mod+Shift+R"     ; desc "Toggle screen recording"
          key "Mod+Shift+D"     ; desc "Display layout (wdisplays)"
          key "Mod+Ctrl+R"      ; desc "Rotate screen (rofi menu)"

          header "Scratchpads"
          key "Mod+M"           ; desc "Pulsemixer (audio mixer)"
          key "Mod+T"           ; desc "btop (system monitor)"
          key "Mod+N"           ; desc "Scratch notes"
          key "Mod+Y"           ; desc "Yazi (file manager)"
          key "Mod+?"           ; desc "This cheatsheet"
          key "Mod+-"           ; desc "Cycle scratchpad windows"
          key "Mod+Shift+-"     ; desc "Send window to scratchpad"

          header "Audio"
          key "Mod+Alt+K / J"   ; desc "Volume up / down"
          key "Mod+Alt+M"       ; desc "Mute toggle"
          key "Mod+Alt+."       ; desc "Next track"
          key "Mod+Alt+,"       ; desc "Previous track"
          key "Mod+Alt+Space"   ; desc "Play / pause"

          header "Brightness"
          key "Mod+Alt+L / H"   ; desc "Brightness up / down"

          header "Focus"
          key "Mod+H/J/K/L"     ; desc "Focus left / down / up / right"
          key "Mod+Arrows"      ; desc "Focus (arrow keys)"
          key "Mod+A"           ; desc "Focus parent container"
          key "Mod+Ctrl+A"      ; desc "Focus child container"
          key "Mod+Space"       ; desc "Toggle focus: tiling ↔ floating"

          header "Move Windows"
          key "Mod+Shift+H/J/K/L" ; desc "Move window"
          key "Mod+Ctrl+Arrows" ; desc "Move workspace to output"

          header "Workspaces"
          key "Mod+1–0"         ; desc "Switch to workspace"
          key "Mod+Shift+1–0"   ; desc "Move window to workspace"
          key "Mod+\`"          ; desc "Back and forth"

          header "Layout"
          key "Mod+F"           ; desc "Fullscreen"
          key "Mod+Shift+Space" ; desc "Toggle floating"
          key "Mod+B"           ; desc "Split horizontal"
          key "Mod+V"           ; desc "Split vertical"
          key "Mod+E"           ; desc "Toggle split"
          key "Mod+R"           ; desc "Resize mode  (then H/J/K/L or arrows)"

          printf '\n%b  Q to close%b\n\n' "$SUBTEXT" "$RESET"
          } | less -R --quit-if-one-screen
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
