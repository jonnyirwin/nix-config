{ config, lib, ... }:

# The terminal emulator itself, as opposed to the terminal-based tools in
# modules/home/terminal/. It draws a window, so it belongs to the desktop and
# follows that gate — a headless host gets the TUI tools without pulling a
# graphical stack into its profile.
let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  fonts = config.jonny.theme.fonts;
in
{
  programs.kitty = lib.mkIf cfg.enable {
    enable = true;

    font = {
      name = fonts.mono.family;
      size = fonts.mono.size + 0.0;
    };

    settings = {
      # ---- Performance and rendering ----
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = "yes";
      confirm_os_window_close = 0;

      # ---- Appearance ----
      background_opacity = "0.9";
      dynamic_background_opacity = "yes";
      window_padding_width = 4;

      # Remote control is what lets sway scripts drive existing kitty windows.
      allow_remote_control = "yes";
      listen_on = "unix:@kitty";

      # ---- Scrollback ----
      scrollback_lines = 10000;
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER";

      # ---- Tabs ----
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";

      shell_integration = "enabled";

      # ---- URLs ----
      open_url_with = "default";
      url_prefixes = "http https file ftp gemini irc gopher mailto news git";
      detect_urls = "yes";

      # ---- Bell ----
      enable_audio_bell = "no";
      visual_bell_duration = "0.0";
      window_alert_on_bell = "yes";
      bell_on_tab = "yes";

      # ---- Mouse and selection ----
      mouse_hide_wait = "3.0";
      copy_on_select = "yes";
      strip_trailing_spaces = "smart";
      rectangle_select_modifiers = "ctrl+alt";

      # ---- Cursor ----
      cursor_shape = "block";
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = "15.0";

      # ---- Colours (derived from jonny.theme) ----
      foreground = p.fg;
      background = p.bg;
      selection_foreground = p.bg;
      selection_background = p.highlight;

      cursor = p.highlight;
      cursor_text_color = p.bg;
      url_color = p.highlight;

      active_border_color = p.borderActive;
      inactive_border_color = p.border;
      bell_border_color = p.warning;

      wayland_titlebar_color = "system";

      active_tab_foreground = p.bgInset;
      active_tab_background = p.accent; # follows jonny.theme.accent
      inactive_tab_foreground = p.fg;
      inactive_tab_background = p.bgAlt;
      tab_bar_background = p.bgInset;

      mark1_foreground = p.bg;
      mark1_background = p.borderActive;
      mark2_foreground = p.bg;
      mark2_background = p.hues.purple;
      mark3_foreground = p.bg;
      mark3_background = p.hues.blue;

      # The 16 terminal colours. These come from the scheme's own ANSI mapping
      # rather than being assembled from roles: a scheme that specifies its
      # terminal palette deliberately (Gruvbox and Nord both do) would
      # otherwise be second-guessed here.
      color0 = p.ansi.black;
      color1 = p.ansi.red;
      color2 = p.ansi.green;
      color3 = p.ansi.yellow;
      color4 = p.ansi.blue;
      color5 = p.ansi.magenta;
      color6 = p.ansi.cyan;
      color7 = p.ansi.white;

      color8 = p.ansi.brightBlack;
      color9 = p.ansi.brightRed;
      color10 = p.ansi.brightGreen;
      color11 = p.ansi.brightYellow;
      color12 = p.ansi.brightBlue;
      color13 = p.ansi.brightMagenta;
      color14 = p.ansi.brightCyan;
      color15 = p.ansi.brightWhite;
    };

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";

      "ctrl+equal" = "change_font_size all +2.0";
      "ctrl+minus" = "change_font_size all -2.0";
      "ctrl+0" = "change_font_size all 0";

      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+w" = "close_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";

      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+q" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
    };

    # Nerd Font icon ranges, and right-click to paste PRIMARY (the trackball has
    # no middle button). Neither has a structured HM option.
    extraConfig = ''
      mouse_map right press ungrabbed paste_from_selection

      symbol_map U+E0A0-U+E0A3,U+E0B0-U+E0BF,U+E0C0-U+E0C7 Symbols Nerd Font Mono
      symbol_map U+E200-U+E2A9 Symbols Nerd Font Mono
      symbol_map U+E300-U+E3E3 Symbols Nerd Font Mono
      symbol_map U+E5FA-U+E6AC Symbols Nerd Font Mono
      symbol_map U+E700-U+E7C5 Symbols Nerd Font Mono
      symbol_map U+F000-U+F2E0 Symbols Nerd Font Mono
    '';
  };
}
