{ config, pkgs, lib, ... }:

# ============================================================
# Tmux — fully declarative
# ============================================================
#
# This replaces the previous arrangement (a mkOutOfStoreSymlink to
# ~/.dotfiles/tmux/.config/tmux/tmux.conf plus tpm cloning plugins at
# runtime). Everything now comes from the store:
#
#   * Plugins are nixpkgs derivations, loaded by home-manager's
#     `programs.tmux.plugins` — no tpm, no network at first launch.
#   * Catppuccin comes from the catppuccin/nix HM module
#     (`catppuccin.tmux.enable`), so it follows `jonny.theme.flavor` rather
#     than a `@catppuccin_flavour` line in a hand-written conf.
#   * The accent colour is derived from `jonny.theme.accent` instead of being
#     rewritten in place by ~/.dotfiles/catppuccin/.local/bin/set-accent.
#     To change it: edit `jonny.theme.accent` and rebuild.
#
# Config assembly order (see home-manager's programs/tmux.nix):
#   1. mkBefore  — options generated from programs.tmux.* below
#   2. plugins   — each plugin's extraConfig, then its `run-shell`
#   3. mkAfter   — programs.tmux.extraConfig (this file's `extraConfig`)
#
# That ordering is load-bearing: our status/window/pane format overrides
# must land *after* catppuccin's run-shell, or the plugin would clobber them.
# ============================================================

let
  # The catppuccin/nix module exposes the accent as a name only, not a hex
  # value, so read the resolved colour from jonny.theme (see lib/palette.nix).
  p = config.jonny.theme.palette;
  accentHex = p.accent;

  # Clipboard shim used by copy-mode bindings and `copy-command`.
  # Prefers Wayland, then X11, and otherwise consumes stdin so the pipeline
  # still succeeds — tmux's `set-clipboard on` will already have emitted OSC 52,
  # which is how SSH sessions to an OSC-52-aware terminal get the selection.
  tmux-copy = pkgs.writeShellScriptBin "tmux-copy" ''
    if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null 2>&1; then
      exec wl-copy
    fi

    if [ -n "$DISPLAY" ]; then
      if command -v xclip >/dev/null 2>&1; then
        exec xclip -selection clipboard
      fi
      if command -v xsel >/dev/null 2>&1; then
        exec xsel --clipboard --input
      fi
    fi

    cat >/dev/null
  '';

  # Marks panes running an AI assistant and exposes @ai_total / @ai_pane_tool /
  # @ai_window_tool for the status line. Not in nixpkgs, so built here.
  tmux-ai-status = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-ai-status";
    # mkTmuxPlugin defaults to "<pluginName with _>.tmux"; this repo's
    # entrypoint is ai-status.tmux, so point at it explicitly. Getting this
    # wrong builds fine and only fails at `run-shell` time inside tmux.
    rtpFilePath = "ai-status.tmux";
    version = "unstable-2026-04-15";
    src = pkgs.fetchFromGitHub {
      owner = "jonnyirwin";
      repo = "tmux-ai-status";
      rev = "74aa19f93060ba42b5ad3313b689d8722eee0cd0";
      hash = "sha256-Deoak43P9Uj1kKoFM7yfzIE4xGNpcSlZC4gkaca5gSE=";
    };
  };
in
{
  home.packages = [
    tmux-copy
    pkgs.wl-clipboard # wl-copy, picked up by tmux-copy under Wayland
  ];

  # Catppuccin via the flake module rather than a tpm plugin. It appends the
  # themed plugin to programs.tmux.plugins and passes through the global flavor.
  catppuccin.tmux.enable = true;

  programs.tmux = {
    enable = true;

    prefix = "C-a";
    baseIndex = 1;
    escapeTime = 100;
    focusEvents = true;
    mouse = true;

    # The copy-mode-vi bindings below only take effect with vi mode-keys.
    # The old conf relied on tmux inferring this from $EDITOR; make it explicit.
    keyMode = "vi";

    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator

      resurrect

      {
        plugin = continuum;
        # Must be set before continuum's run-shell, which is why it lives on
        # the plugin rather than in extraConfig.
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }

      {
        plugin = tmux-ai-status;
        extraConfig = ''
          set -g @ai_window_marker off
        '';
      }
    ];

    extraConfig = ''
      # ---- Panes ----
      # baseIndex above only covers windows.
      set -g pane-base-index 1

      # ---- Terminal capabilities ----
      # True colour plus italics, which tmux-256color alone doesn't advertise.
      set -as terminal-overrides ',*:Tc,*:sitm=\E[3m,*:ritm=\E[23m'

      # ---- Clipboard ----
      # `set-clipboard on` makes tmux emit OSC 52, which is what lets SSH
      # sessions (e.g. Windows Terminal) round-trip the selection to the host.
      set -g set-clipboard on
      set -s copy-command '${lib.getExe tmux-copy}'

      # Keep Wayland/SSH environment fresh in reattached sessions.
      set -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

      # ---- Bindings ----
      bind r source-file ${config.xdg.configHome}/tmux/tmux.conf \; display "Reloaded tmux config."

      bind | split-window -h
      bind - split-window -v

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Copy mode — mouse drag-release also lands here via MouseDragEnd1Pane.
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel '${lib.getExe tmux-copy}'
      bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel '${lib.getExe tmux-copy}'
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel '${lib.getExe tmux-copy}'

      # prefix + T renames the current pane. (prefix + , stays as rename-window.)
      bind T command-prompt -p "pane title:" "select-pane -T '%%'"

      # ------------------------------------------------------------
      # Theme overrides — must come after catppuccin's run-shell.
      # ------------------------------------------------------------
      # Single source for "the focus colour", derived from catppuccin.accent.
      set -g @thm_accent "${accentHex}"

      # Window tabs mirror the right-side pills — flat surface0 with rounded
      # caps, inactive in overlay_1, current in accent-on-crust like waybar's
      # focused #workspaces button.
      #
      # Bell alerts are folded into the pill itself rather than catppuccin's
      # blanket yellow style (which bled onto the bg=default caps and drew a
      # rectangle around the pill). Neutralise that style; the inactive
      # window-status-format below then turns the pill TEXT yellow on a bell via
      # #{?window_bell_flag,...}. The current window is deliberately left plain:
      # tmux clears window_bell_flag the instant the attached client renders the
      # window you're on, so a current-pill highlight could never actually paint
      # (verified — attachment, not focus, is the gate).
      set -g window-status-bell-style "default"
      set -g window-status-separator " "
      set -g window-status-format "#[fg=#{@thm_surface_0},bg=default]#[fg=#{?window_bell_flag,#{@thm_yellow},#{@thm_overlay_1}},bg=#{@thm_surface_0}] #I:#W#{?@ai_window_tool, 󰚩,} #[fg=#{@thm_surface_0},bg=default]"
      set -g window-status-current-format "#[fg=#{@thm_accent},bg=default]#[fg=#{@thm_crust},bg=#{@thm_accent}] #I:#W#{?@ai_window_tool, 󰚩,} #[fg=#{@thm_accent},bg=default]"

      # Right-side modules: flat surface0 pills with accent icon+text, waybar-style.
      set -g "@catppuccin_status_application" "#[fg=#{@thm_surface_0},bg=default]#[fg=#{@thm_accent},bg=#{@thm_surface_0}]󰆍 #{pane_current_command} #[fg=#{@thm_surface_0},bg=default]"
      set -g "@catppuccin_status_date"        "#[fg=#{@thm_surface_0},bg=default]#[fg=#{@thm_peach},bg=#{@thm_surface_0}] 󰃭 %Y-%m-%d #[fg=#{@thm_surface_0},bg=default]"
      set -g "@catppuccin_status_time"        "#[fg=#{@thm_surface_0},bg=default]#[fg=#{@thm_blue},bg=#{@thm_surface_0}] 󰥔 %H:%M #[fg=#{@thm_surface_0},bg=default]"
      set -g "@catppuccin_status_ai"          "#[fg=#{@thm_surface_0},bg=default]#[fg=#{@thm_accent},bg=#{@thm_surface_0}] 󰚩 #{@ai_total} #[fg=#{@thm_surface_0},bg=default]"
      set -g "@catppuccin_status_session"     "#[fg=#{@thm_surface_0},bg=default]#[fg=#{@thm_teal},bg=#{@thm_surface_0}] ⊞ #S #[fg=#{@thm_surface_0},bg=default]"

      set -g status-left ""
      set -g status-left-length 100
      set -g status-right-length 100
      set -g status-right "#{E:@catppuccin_status_application} #{E:@catppuccin_status_date} #{E:@catppuccin_status_time} #{?@ai_total,#{E:@catppuccin_status_ai} ,}#{E:@catppuccin_status_session}"

      # Pane borders: subtle grey + accent focus, matching waybar.
      set -g pane-border-style "fg=${p.surfaceAlt}"
      set -g pane-active-border-style "fg=#{@thm_accent}"
      set -g pane-border-lines single

      # Per-pane pill on the top border — same vocabulary as window tabs and the
      # right-side status modules. Inactive: flat surface0 with overlay_1 text.
      # Active: crust-on-accent, matching the focused window tab / waybar workspace.
      # Title chip ("· name") only shows if the pane title differs from the host
      # default, so an un-named pane stays clean.
      set -g pane-border-status top
      set -g pane-border-format "#[align=right]#{?pane_active,#[fg=#{@thm_accent}#,bg=default]#[fg=#{@thm_crust}#,bg=#{@thm_accent}] #P #{pane_current_command}#{?#{!=:#{pane_title},#{host_short}}, · #{pane_title},} #[fg=#{@thm_accent}#,bg=default]#[bg=default],#[fg=#{@thm_surface_0}#,bg=default]#[fg=#{@thm_overlay_1}#,bg=#{@thm_surface_0}] #P #{pane_current_command}#{?#{!=:#{pane_title},#{host_short}}, · #{pane_title},} #[fg=#{@thm_surface_0}#,bg=default]#[bg=default]}#{?@ai_pane_tool, #[fg=#{@thm_accent}#,bg=default]󰚩,}"
    '';
  };
}
