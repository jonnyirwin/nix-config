{ config, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  s = cfg.scripts;
  k = cfg.keys;

  myLib = import ../../../../lib { inherit lib; };

  # jonny.desktop.keys speaks "Mod+Shift+S"; sway wants "Mod4+Shift+s". Every
  # hand-chosen binding below goes through here, so the declaration in
  # actions.nix is the only place a key is written down — the command menu and
  # the cheatsheet read the same one.
  bind = myLib.swayBinding;

  # Still needed for the generated families below — focus, window movement,
  # workspace switching — which are built from a direction or a number rather
  # than from a named action.
  mod = "Mod4"; # Super
  term = lib.getExe pkgs.kitty;

  left = "h";
  down = "j";
  up = "k";
  right = "l";

  menu = "rofi -show drun -show-icons -lines 5";

  scratchpad = lib.getExe s.scratchpad-toggle;

  # The definitions — app_id, size, and the command that creates the window if
  # it is not already running — live in jonny.desktop.scratchpads, because the
  # command menu summons the same windows and should not carry a second copy of
  # how. The window rules in `window.commands` below key off the same app_ids.
  scratchpadBindings = lib.mapAttrs'
    (_: sp: lib.nameValuePair (bind sp.key)
      "exec ${scratchpad} ${sp.id} ${toString sp.width} ${toString sp.height} ${sp.command}")
    cfg.scratchpads;

  # Mod+1..0 → workspace N, Mod+Shift+1..0 → move container to workspace N.
  workspaceKeys = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" ];
  workspaceNumber = key: if key == "0" then "10" else key;

  workspaceBindings = lib.listToAttrs (lib.concatMap
    (key: [
      (lib.nameValuePair "${mod}+${key}" "workspace number ${workspaceNumber key}")
      (lib.nameValuePair "${mod}+Shift+${key}" "move container to workspace number ${workspaceNumber key}")
    ])
    workspaceKeys);

  directions = {
    "${left}" = "left";
    "${down}" = "down";
    "${up}" = "up";
    "${right}" = "right";
    "Left" = "left";
    "Down" = "down";
    "Up" = "up";
    "Right" = "right";
  };

  focusBindings = lib.mapAttrs' (key: dir: lib.nameValuePair "${mod}+${key}" "focus ${dir}") directions;
  moveBindings = lib.mapAttrs' (key: dir: lib.nameValuePair "${mod}+Shift+${key}" "move ${dir}") directions;

  outputMoveBindings = lib.listToAttrs (map
    (dir: lib.nameValuePair "${mod}+Control+${dir}" "move workspace to output ${lib.toLower dir}")
    [ "Left" "Right" "Up" "Down" ]);
in
{
  config = lib.mkIf (cfg.enable && cfg.compositor == "sway") {
    wayland.windowManager.sway = {
      enable = true;

      # NixOS installs and wraps sway itself (modules/nixos/desktop/sway.nix);
      # setting this to null stops HM installing a second, unwrapped copy.
      package = null;

      # The session is started by the display manager (SDDM), not HM, so do
      # not let HM manage sway-session.target's startup — but waybar and mako
      # still bind to it.
      systemd.enable = true;

      # Config validation needs a sway package to run against; ours is null
      # because NixOS installs the wrapped sway (modules/nixos/desktop/sway.nix).
      checkConfig = false;

      config = {
        modifier = mod;
        terminal = term;
        inherit menu left down up right;

        # ---- Appearance ----
        gaps = {
          inner = 5;
          smartGaps = true;
          smartBorders = "on";
        };

        floating = {
          border = 0;
          titlebar = false;
        };

        colors =
          let
            # Shared across focused/unfocused: only the border colour differs.
            common = {
              background = p.bg;
              text = p.fg;
              indicator = p.highlight;
            };
            withBorder = colour: common // { border = colour; childBorder = colour; };
          in
          {
            focused = withBorder p.borderActive;
            focusedInactive = withBorder p.border;
            unfocused = withBorder p.border;
            placeholder = withBorder p.border;

            urgent = {
              border = p.hues.orange;
              background = p.bg;
              text = p.hues.orange;
              indicator = p.border;
              childBorder = p.hues.orange;
            };

            background = p.bg;
          };

        # ---- Input ----
        input = {
          "*" = { xkb_layout = "gb"; };
          # The trackball has no middle button.
          "type:pointer" = { middle_emulation = "enabled"; };
        };

        seat."*" = { hide_cursor = "8000"; };

        # ---- Output ----
        # Was ~/.config/sway/config.d/display-settings.conf, generated at runtime
        # by resolution-switcher.sh. Declared here instead; use `wdisplays` for
        # ad-hoc changes and fold anything permanent back into this block.
        output = cfg.outputs;

        workspaceAutoBackAndForth = true;

        # Start on workspace 1, not 10.
        #
        # sway names a newly created workspace after the *first* `workspace …`
        # binding in the config file whose target does not exist yet — see
        # workspace_next_name / workspace_name_from_binding in sway's
        # tree/workspace.c, which ranks candidates by binding->order, i.e.
        # position in the file. Home Manager emits keybindings sorted by
        # attribute name, so `bindsym Mod4+0 workspace number 10` landed ahead
        # of `Mod4+1` and every fresh workspace — including the one sway creates
        # at login — got named "10".
        #
        # defaultWorkspace hoists the matching binding to the top of the bindsym
        # block, which makes `workspace number 1` the earliest candidate. The
        # string must match the binding's action verbatim for the hoist to fire.
        defaultWorkspace = "workspace number 1";

        # ---- Bars ----
        # waybar runs as a systemd user unit bound to sway-session.target
        # (see waybar.nix), not as a sway `bar` block.
        bars = [ ];

        # ---- Window rules ----
        window = {
          border = 0;
          titlebar = false;

          commands = [
            # Scratchpad apps: float at a fixed size, centred, parked in the
            # scratchpad until their binding summons them.
            {
              criteria.app_id = "^float-(mixer|btop|notes|cheatsheet|yazi)$";
              command = "floating enable, move position center, move scratchpad";
            }

            # No borders anywhere.
            { criteria.class = ".*"; command = "border none"; }
            { criteria.app_id = ".*"; command = "border none"; }

            # Don't blank the screen during fullscreen video.
            { criteria.app_id = "firefox"; command = "inhibit_idle fullscreen"; }
            { criteria.app_id = "mpv"; command = "inhibit_idle fullscreen"; }

            # Dialogs and utilities float.
            { criteria.window_role = "pop-up"; command = "floating enable"; }
            { criteria.window_type = "dialog"; command = "floating enable"; }
            { criteria.app_id = "pavucontrol"; command = "floating enable"; }
            { criteria.app_id = "nm-connection-editor"; command = "floating enable"; }
            { criteria.window_role = "GtkFileChooserDialog"; command = "floating enable, resize set 800 600"; }

            # Picture-in-Picture follows you across workspaces.
            { criteria.title = "^Picture-in-Picture$"; command = "floating enable, sticky enable, border none"; }
          ];
        };

        # ---- Startup ----
        startup = [
          # Belt and braces: land on workspace 1 at login. The binding order
          # fix (see workspaceKeys) is what actually makes sway *name* the
          # initial workspace 1; this just guarantees focus lands there once
          # the startup apps have finished shuffling windows around.
          # Not `always` — a reload should not yank you back to 1.
          { command = "${lib.getExe' pkgs.sway "swaymsg"} workspace number 1"; }

          # `current`, not `next`: a config reload should put the wallpaper
          # back, not step past it.
          { command = "${lib.getExe s.wallpaper} current"; always = true; }
          { command = lib.getExe s.clipboard-sync; }
          { command = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} store"; }

          # Wayland serves a selection from the client that set it, so closing
          # that client takes the clipboard with it. This holds a copy so a
          # copy-then-quit still pastes. Regular clipboard only — PRIMARY is
          # already mirrored by clipboard-sync above, and having both manage
          # the same selection makes them fight over it.
          { command = "${lib.getExe pkgs.wl-clip-persist} --clipboard regular"; }
          { command = lib.getExe pkgs.autotiling; }
          # udiskie is deliberately not here — it is a systemd user unit in
          # desktop/storage.nix so it starts after udisks2 and can be restarted
          # without ending the session.
          { command = "${lib.getExe' pkgs.blueman "blueman-applet"}"; }

          # Not for the tray icon, though it provides one. This is the session's
          # NetworkManager *secret agent*: without one running, nothing can be
          # asked for a wifi passphrase, so `nmcli device wifi connect` on a
          # secured network fails with no prompt and no explanation. That was
          # invisible on the wired hosts and left mac — wifi-only — with no way
          # onto a network at all.
          #
          # It also owns the retry path. NM marks a rejected secret invalid and
          # re-asks; network-menu used to hand-roll the prompt and could not,
          # which turned one mistyped passphrase into a permanently failing
          # saved profile.
          { command = "${lib.getExe' pkgs.networkmanagerapplet "nm-applet"} --indicator"; }

          # Scratchpads are deliberately not pre-launched: each one is a kitty
          # instance, and starting five at login costs memory and a burst of
          # work for windows that may never be summoned. scratchpad-toggle
          # creates one on first press instead — one slower summon, then it
          # stays resident for the rest of the session.
        ];

        # This replaces the HM module's default keybinding set outright rather
        # than merging with it — the map below is the complete binding surface.
        # Names come from jonny.desktop.keys through `bind`, so a rebind is one
        # edit in actions.nix and the cheatsheet and command menu follow.
        keybindings =
          {
            # ---- Basics ----
            "${bind k.terminal}" = "exec ${term}";
            "${bind k.kill}" = "kill";
            "${bind k.launcher}" = "exec ${menu}";
            "${bind k.reload}" = "reload";
            "${bind k.powerMenu}" = "exec ${lib.getExe s.power-menu}";
            "${bind k.lockScreen}" = "exec ${lib.getExe s.lock-screen}";
            "${bind k.windowSwitcher}" = "exec ${lib.getExe s.window-switcher}";
            "${bind k.networkMenu}" = "exec ${lib.getExe s.network-menu}";
            "${bind k.idleInhibitor}" = "exec ${lib.getExe s.idle-inhibitor-toggle}";
            "${bind k.pomodoro}" = "exec ${cfg.pomodoro.package}/bin/pomodoro-menu";
            "${bind k.toggleBar}" = "exec ${lib.getExe' pkgs.psmisc "killall"} -SIGUSR1 waybar";

            # Put the most recently expired notification back on screen. mako
            # keeps max-history of them (desktop/mako.nix).
            "${bind k.notificationReplay}" = "exec ${lib.getExe s.notification-replay}";

            # The command menu is on trial alongside the bindings above, not in
            # place of them — see the comment in desktop/command-menu.nix.
            "${bind k.commandMenu}" = "exec ${lib.getExe cfg.commandMenu}";

            # Clipboard history
            "${bind k.clipboardHistory}" = "exec ${lib.getExe pkgs.cliphist} list | rofi -dmenu -p 'Clipboard' | ${lib.getExe pkgs.cliphist} decode | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}";
            # Paste PRIMARY (middle-click alternative)
            "${bind k.pastePrimary}" = "exec ${lib.getExe' pkgs.wl-clipboard "wl-paste"} -p | ${lib.getExe pkgs.wtype} -";

            # ---- Capture and pickers ----
            "${bind k.screenshotRegion}" = "exec ${lib.getExe s.screenshot-region}";
            "${bind k.screenshotAnnotate}" = "exec ${lib.getExe s.screenshot-annotate}";
            "${bind k.emojiPicker}" = "exec ${lib.getExe s.emoji-picker}";
            "${bind k.ocrRegion}" = "exec ${lib.getExe s.ocr-region}";
            "${bind k.qrDecode}" = "exec ${lib.getExe s.qr-decode}";
            "${bind k.colorPicker}" = "exec ${lib.getExe s.color-picker}";
            "${bind k.recordToggle}" = "exec ${lib.getExe s.record-toggle}";

            # ---- Audio and media ----
            "${bind k.volumeUp}" = "exec ${lib.getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%+";
            "${bind k.volumeDown}" = "exec ${lib.getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
            "${bind k.volumeMute}" = "exec ${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "${bind k.mediaNext}" = "exec ${lib.getExe pkgs.playerctl} next";
            "${bind k.mediaPrevious}" = "exec ${lib.getExe pkgs.playerctl} previous";
            "${bind k.mediaPlayPause}" = "exec ${lib.getExe pkgs.playerctl} play-pause";

            # ---- Brightness ----
            # Not brightnessctl directly: the script falls through to DDC/CI
            # when there is no internal panel, which is every host here but
            # mac and precision.
            "${bind k.brightnessUp}" = "exec ${lib.getExe s.brightness} up";
            "${bind k.brightnessDown}" = "exec ${lib.getExe s.brightness} down";

            # ---- Layout ----
            "${bind k.splitHorizontal}" = "splith";
            "${bind k.splitVertical}" = "splitv";
            "${bind k.toggleSplit}" = "layout toggle split";
            "${bind k.fullscreen}" = "fullscreen";
            "${bind k.floatingToggle}" = "floating toggle";
            "${bind k.focusModeToggle}" = "focus mode_toggle";
            "${bind k.focusParent}" = "focus parent";
            "${bind k.focusChild}" = "focus child";
            "${bind k.resizeMode}" = "mode resize";

            # ---- Scratchpad ----
            "${bind k.scratchpadMove}" = "move scratchpad";
            "${bind k.scratchpadShow}" = "scratchpad show";

            # ---- Workspaces ----
            "${bind k.workspaceBackAndForth}" = "workspace back_and_forth";

            # ---- Display layout ----
            # Replaces the old resolution-switcher.sh: permanent layout belongs
            # in `jonny.desktop.outputs`, ad-hoc changes go through wdisplays.
            "${bind k.displayLayout}" = "exec ${lib.getExe pkgs.wdisplays}";
            # Quick rotate of the focused output via a rofi menu. Ephemeral —
            # the permanent default lives in jonny.desktop.outputs.
            "${bind k.screenRotate}" = "exec ${lib.getExe s.screen-rotate}";

            # ---- Wallpaper ----
            # Step through ~/Pictures/Wallpapers in order, without waiting for
            # the daily timer.
            "${bind k.wallpaper}" = "exec ${lib.getExe s.wallpaper} next";

            # ---- External ----
            # whisper.cpp lives outside this flake; the binding is a no-op until
            # that checkout exists.
            "${bind k.voiceInput}" = "exec ${config.home.homeDirectory}/git/whisper.cpp/voice-input-toggle.sh";
          }
          // focusBindings
          // moveBindings
          // outputMoveBindings
          // workspaceBindings
          // scratchpadBindings
          // cfg.extraKeybindings;
      };

      extraConfig = ''
        # Not exposed as structured options by the HM module.
        tiling_drag enable
        titlebar_border_thickness 0
        titlebar_padding 0

        # Idle: lock at 5 min, blank displays at 10, and lock before sleep.
        exec ${lib.getExe pkgs.swayidle} -w \
          timeout 300 '${lib.getExe s.lock-screen}' \
          timeout 600 'swaymsg "output * power off"' \
            resume 'swaymsg "output * power on"' \
          before-sleep '${lib.getExe s.lock-screen}'
      '';
    };
  };
}
