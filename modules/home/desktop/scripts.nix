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
        # QT_STYLE_OVERRIDE is needed because sway's exec environment has no
        # QT_QPA_PLATFORMTHEME (that is exported for interactive shells only),
        # so the toolbar would otherwise render in the default light style.
        export XDG_CURRENT_DESKTOP=sway
        export QT_QPA_PLATFORM=wayland
        export QT_STYLE_OVERRIDE=Adwaita-Dark

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
      runtimeInputs = with pkgs; [ networkmanager rofi coreutils ];
      text = ''
        wifi_status=$(nmcli radio wifi)

        # Not `[ ... ] && x=y`: under `set -e` a false test would abort the script.
        wifi_icon="󰤭"
        if [ "$wifi_status" = "on" ]; then wifi_icon="󰤨"; fi

        connected=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)

        options="$wifi_icon Toggle WiFi"

        if [ "$wifi_status" = "on" ]; then
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
            if [ "$wifi_status" = "on" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi
            ;;
          "Manage connections")
            nmcli connection show | rofi -dmenu -p "Connections" || true
            ;;
          *"(connected)")
            network="''${choice% (connected)}"
            nmcli connection down "''${network#* }"
            ;;
          "󰒕"*)
            nmcli device wifi connect "''${choice#* }"
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
      runtimeInputs = with pkgs; [ swaybg findutils coreutils procps ];
      text = ''
        dir="''${1:-${wallpaperDir}}"

        pick=$(find "$dir" -type f \
          \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.jxl' \) -print0 2>/dev/null \
          | shuf -z -n 1 | tr -d '\0' || true)

        # Nothing to show; leave whatever swaybg is already doing alone.
        [ -n "$pick" ] || exit 0

        pkill -x swaybg || true
        swaybg -i "$pick" -m fill &
        disown
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

    idle-inhibitor-toggle = {
      runtimeInputs = with pkgs; [ systemd procps coreutils ];
      text = ''
        pidfile="''${XDG_RUNTIME_DIR:-/tmp}/idle-inhibitor.pid"

        if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
          kill "$(cat "$pidfile")"
          rm -f "$pidfile"
        else
          systemd-inhibit --what=idle --who="waybar-toggle" \
            --why="Manual idle inhibitor" --mode=block sleep infinity &
          echo $! > "$pidfile"
        fi

        # Refresh the waybar custom/idle-inhibitor module.
        pkill -RTMIN+10 waybar || true
      '';
    };

    idle-inhibitor-status = {
      runtimeInputs = with pkgs; [ coreutils procps ];
      text = ''
        pidfile="''${XDG_RUNTIME_DIR:-/tmp}/idle-inhibitor.pid"

        if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
          echo ""
        else
          echo ""
        fi
      '';
    };

    # ---- Reference ----
    cheatsheet = {
      runtimeInputs = with pkgs; [ less ];
      text =
        let
          accent = rgbOf p.accent;
          blue = rgbOf p.blue;
          lavender = rgbOf p.lavender;
          subtext = rgbOf p.subtext0;
          text' = rgbOf p.text;
          surface = rgbOf p.surface2;
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
