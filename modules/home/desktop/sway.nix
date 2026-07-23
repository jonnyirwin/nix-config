{ config, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  s = cfg.scripts;

  mod = "Mod4"; # Super
  term = lib.getExe pkgs.kitty;

  left = "h";
  down = "j";
  up = "k";
  right = "l";

  menu = "rofi -show drun -show-icons -lines 5";

  scratchpad = lib.getExe s.scratchpad-toggle;

  # Every scratchpad follows the same shape: an app_id, a size, and the command
  # that creates it if it is not already running. The window rules in
  # `window.commands` below key off the same app_id.
  # `respawn` wraps the command in a loop so quitting the program inside the
  # scratchpad leaves the window there rather than destroying it.
  respawn = cmd: "${lib.getExe pkgs.bash} -c 'while true; do ${cmd}; done'";

  scratchpads = {
    "${mod}+m" = { id = "float-mixer"; w = 900; h = 500; cmd = "${term} --class=float-mixer ${lib.getExe pkgs.pulsemixer}"; };
    "${mod}+t" = { id = "float-btop"; w = 1200; h = 900; cmd = "${term} --class=float-btop ${respawn (lib.getExe pkgs.btop)}"; };
    "${mod}+n" = { id = "float-notes"; w = 1000; h = 700; cmd = "${term} --class=float-notes nvim ${config.home.homeDirectory}/notes/scratch.md"; };
    "${mod}+y" = { id = "float-yazi"; w = 1200; h = 800; cmd = "${term} --class=float-yazi ${lib.getExe pkgs.yazi}"; };
    "${mod}+question" = { id = "float-cheatsheet"; w = 960; h = 640; cmd = "${term} --class=float-cheatsheet ${respawn (lib.getExe s.cheatsheet)}"; };
  };

  scratchpadBindings = lib.mapAttrs
    (_: v: "exec ${scratchpad} ${v.id} ${toString v.w} ${toString v.h} ${v.cmd}")
    scratchpads;

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
  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;

      # NixOS installs and wraps sway itself (modules/nixos/desktop/sway.nix);
      # setting this to null stops HM installing a second, unwrapped copy.
      package = null;

      # The session is started by greetd, not by HM, so do not let HM manage
      # sway-session.target's startup — but waybar and mako still bind to it.
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
              background = p.base;
              inherit (p) text;
              indicator = p.rosewater;
            };
            withBorder = colour: common // { border = colour; childBorder = colour; };
          in
          {
            focused = withBorder p.lavender;
            focusedInactive = withBorder p.overlay0;
            unfocused = withBorder p.overlay0;
            placeholder = withBorder p.overlay0;

            urgent = {
              border = p.peach;
              background = p.base;
              text = p.peach;
              indicator = p.overlay0;
              childBorder = p.peach;
            };

            background = p.base;
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
          { command = lib.getExe s.random-wallpaper; always = true; }
          { command = lib.getExe s.clipboard-sync; }
          { command = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} store"; }
          { command = lib.getExe pkgs.autotiling; }
          { command = "${lib.getExe pkgs.udiskie} --no-notify"; }

          # Pre-launch the scratchpads so their first summon is instant.
          # The window.commands rule above parks them out of sight.
        ] ++ lib.mapAttrsToList (_: v: { command = v.cmd; }) scratchpads;

        # This replaces the HM module's default keybinding set outright rather
        # than merging with it — the map below is the complete binding surface.
        keybindings =
          {
            # ---- Basics ----
            "${mod}+Return" = "exec ${term}";
            "${mod}+Shift+q" = "kill";
            "${mod}+d" = "exec ${menu}";
            "${mod}+Shift+c" = "reload";
            "${mod}+Shift+e" = "exec ${lib.getExe s.power-menu}";
            "${mod}+Shift+x" = "exec ${lib.getExe s.lock-screen}";
            "${mod}+Tab" = "exec ${lib.getExe s.window-switcher}";
            "${mod}+Shift+n" = "exec ${lib.getExe s.network-menu}";
            "${mod}+i" = "exec ${lib.getExe s.idle-inhibitor-toggle}";
            "${mod}+p" = "exec ${cfg.pomodoro.package}/bin/pomodoro-menu";
            "${mod}+o" = "exec ${lib.getExe' pkgs.psmisc "killall"} -SIGUSR1 waybar";

            # Clipboard history
            "${mod}+c" = "exec ${lib.getExe pkgs.cliphist} list | rofi -dmenu -p 'Clipboard' | ${lib.getExe pkgs.cliphist} decode | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}";
            # Paste PRIMARY (middle-click alternative)
            "${mod}+Shift+v" = "exec ${lib.getExe' pkgs.wl-clipboard "wl-paste"} -p | ${lib.getExe pkgs.wtype} -";

            # ---- Capture and pickers ----
            "${mod}+s" = "exec ${lib.getExe s.screenshot-region}";
            "${mod}+Shift+s" = "exec ${lib.getExe s.screenshot-annotate}";
            "${mod}+period" = "exec ${lib.getExe s.emoji-picker}";
            "${mod}+Shift+o" = "exec ${lib.getExe s.ocr-region}";
            "${mod}+Shift+p" = "exec ${lib.getExe s.color-picker}";
            "${mod}+Shift+r" = "exec ${lib.getExe s.record-toggle}";

            # ---- Audio and media ----
            "${mod}+Mod1+k" = "exec ${lib.getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%+";
            "${mod}+Mod1+j" = "exec ${lib.getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
            "${mod}+Mod1+m" = "exec ${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "${mod}+Mod1+period" = "exec ${lib.getExe pkgs.playerctl} next";
            "${mod}+Mod1+comma" = "exec ${lib.getExe pkgs.playerctl} previous";
            "${mod}+Mod1+space" = "exec ${lib.getExe pkgs.playerctl} play-pause";

            # ---- Brightness ----
            "${mod}+Mod1+l" = "exec ${lib.getExe pkgs.brightnessctl} set 5%+";
            "${mod}+Mod1+h" = "exec ${lib.getExe pkgs.brightnessctl} set 5%-";

            # ---- Layout ----
            "${mod}+b" = "splith";
            "${mod}+v" = "splitv";
            "${mod}+e" = "layout toggle split";
            "${mod}+f" = "fullscreen";
            "${mod}+Shift+space" = "floating toggle";
            "${mod}+space" = "focus mode_toggle";
            "${mod}+a" = "focus parent";
            "${mod}+Ctrl+a" = "focus child";
            "${mod}+r" = "mode resize";

            # ---- Scratchpad ----
            "${mod}+Shift+minus" = "move scratchpad";
            "${mod}+minus" = "scratchpad show";

            # ---- Workspaces ----
            "${mod}+grave" = "workspace back_and_forth";

            # ---- Display layout ----
            # Replaces the old resolution-switcher.sh: permanent layout belongs
            # in `jonny.desktop.outputs`, ad-hoc changes go through wdisplays.
            "${mod}+Shift+d" = "exec ${lib.getExe pkgs.wdisplays}";

            # ---- External ----
            # whisper.cpp lives outside this flake; the binding is a no-op until
            # that checkout exists.
            "${mod}+semicolon" = "exec ${config.home.homeDirectory}/git/whisper.cpp/voice-input-toggle.sh";
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
