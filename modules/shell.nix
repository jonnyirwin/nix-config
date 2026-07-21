{ config, pkgs, lib, ... }:

# ============================================================
# Shell environment: Fish, Starship, and CLI integrations
# ============================================================
#
# Design decisions:
#
#   Aliases      — now in home.nix as `home.shellAliases` (shell-agnostic).
#                  This file only contains Fish-specific config.
#
#   Fish config  — SYMLINKED from ~/.dotfiles/fish/config.fish so you
#                  can edit it directly without `home-manager switch`.
#                  The HM fish module installs the binary and generates
#                  vendor_conf.d/ snippets; your config.fish is untouched.
#
#   Starship     — SYMLINKED from dotfiles. The existing TOML is too
#                  well-tuned to worth converting to Nix attributes.
#
#   zoxide / atuin / fzf / direnv — managed via programs.* modules,
#   which write init snippets into Fish's vendor_conf.d/ automatically.
#   Once HM manages these, remove the manual `| source` calls from
#   config.fish (or leave them — they're idempotent).
# ============================================================

{
  # ----------------------------------------------------------
  # Fish shell
  # ----------------------------------------------------------
  # catppuccin.fish.enable conflicts with the xdg.configFile."fish/config.fish"
  # symlink below — both try to write the same file. Keep the live dotfiles
  # symlink (editable without a rebuild) and skip catppuccin fish theming.
  # To use catppuccin in fish, source the theme from your dotfiles config.fish.

  programs.fish = {
    enable = true;

    # Fish-specific init (things that don't make sense as universal aliases).
    # Universal aliases are in home.nix via home.shellAliases.
    shellInit = ''
      # Suppress the default greeting — our starship prompt is greeting enough
      set fish_greeting ""
    '';
  };

  # PATH additions — HM prepends these in the correct order.
  # Replaces the manual `export PATH=...` in config.fish.
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    # ghcup places GHC, cabal, and HLS here (see modules/dev/haskell.nix)
    "${config.home.homeDirectory}/.ghcup/bin"
    # mise shims directory — mise activates this itself, but listing it here
    # ensures it's available even in non-interactive shells (e.g. scripts)
    "${config.home.homeDirectory}/.local/share/mise/shims"
  ];

  # Session variables for all shells (interactive and non-interactive).
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER  = "delta";
    LESS   = "-R";   # interpret ANSI colour codes (needed by delta)
  };

  # NOTE: fish/config.fish is NOT symlinked here. HM's programs.fish module
  # generates it from shellInit/interactiveShellInit. Symlinking it conflicts
  # with HM's generated file and with the catppuccin fish module. Migrate any
  # remaining dotfiles config.fish content into programs.fish.shellInit above.

  xdg.configFile."fish/fish_variables".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/fish/.config/fish/fish_variables";

  # ----------------------------------------------------------
  # Starship prompt
  # ----------------------------------------------------------
  # programs.starship installs the binary and writes the Fish init snippet.
  # The config is symlinked from your dotfiles (overrides HM's generated config).
  programs.starship = {
    enable                = true;
    enableFishIntegration = true;
  };
  xdg.configFile."starship.toml".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/starship/.config/starship.toml";

  # ----------------------------------------------------------
  # zoxide — smarter `cd` with frecency-based ranking
  # ----------------------------------------------------------
  # Adds the `z` command. Use `z foo` instead of `cd` to jump to
  # frequently-visited directories matching "foo".
  #
  # We intentionally do NOT set `options = [ "--cmd cd" ]` — that replaces
  # the shell built-in `cd` entirely, which breaks scripts that rely on
  # POSIX `cd` behaviour (e.g. returning an error code, affecting subshells).
  # Keep `z` as a separate, additive command.
  programs.zoxide = {
    enable                = true;
    enableFishIntegration = true;
    # No options = use `z` for smart jumping, `cd` for normal navigation
  };

  # ----------------------------------------------------------
  # atuin — searchable, syncable shell history
  # ----------------------------------------------------------
  programs.atuin = {
    enable                = false;  # disabled — fzf owns Ctrl-R history search instead
    enableFishIntegration = false;
    settings = {
      search_mode                      = "fuzzy";
      filter_mode_shell_up_key_binding = "session";
      inline_height                    = 20;
    };
  };

  # ----------------------------------------------------------
  # fzf — fuzzy finder
  # ----------------------------------------------------------
  catppuccin.fzf.enable = true;

  programs.fzf = {
    enable                = true;
    enableFishIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    defaultCommand    = "fd --type f --hidden --follow --exclude .git";
    fileWidget.command = "fd --type f --hidden --follow --exclude .git";
  };

  # ----------------------------------------------------------
  # direnv — per-directory environment variables
  # ----------------------------------------------------------
  # `cd` into a directory with an .envrc → its env is automatically loaded.
  # nix-direnv caches nix devShell evaluations so re-entering is instant.
  programs.direnv = {
    enable            = true;
    nix-direnv.enable = true;
  };
}
