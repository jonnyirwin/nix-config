{ config, pkgs, ... }:

# ============================================================
# Programs with catppuccin/nix theming
# ============================================================
#
# catppuccin/nix integration explained
# ─────────────────────────────────────
# The `catppuccin.homeManagerModules.catppuccin` module (imported in
# flake.nix) adds a `catppuccin` sub-option to supported HM programs.
# When you set `programs.foo.catppuccin.enable = true`, the module:
#
#   1. Downloads the official Catppuccin theme file for that program
#   2. Generates the correct config syntax (TOML, JSON, CSS, etc.)
#   3. Writes it to the right location via Home Manager
#
# The global `catppuccin.flavor` and `catppuccin.accent` in home.nix
# set the default so you don't have to repeat "mocha"/"mauve" everywhere.
# Individual programs inherit these defaults but can override them:
#   programs.bat.catppuccin.flavor = "latte";  # light mode for bat only
#
# Programs where we DO use catppuccin/nix (configured here):
#   bat, lazygit — HM manages their config, catppuccin slots in cleanly
#
# Programs where we DON'T use catppuccin/nix (symlinked configs):
#   kitty, tmux, starship, sway — already have Catppuccin hardcoded;
#   enabling catppuccin/nix would generate a SECOND config file that
#   conflicts with the symlink from dotfiles.
# ============================================================

{
  # ----------------------------------------------------------
  # bat — cat replacement with syntax highlighting
  # ----------------------------------------------------------
  # Using programs.bat (HM module) instead of home.packages so we
  # can hook in the catppuccin theme cleanly.
  # The `cat = "bat --style=plain"` alias in shell.nix still works.
  programs.bat = {
    enable = true;
    catppuccin.enable = true;  # writes ~/.config/bat/themes/Catppuccin Mocha.tmTheme
                               # and sets it as the active theme via --theme flag
    config = {
      # Default style when bat is called directly (not via the `cat` alias).
      # "numbers,changes,header" shows line numbers, git change markers, and filename.
      style = "numbers,changes,header";
      # Use italics for comments and keywords (your terminal supports it — Dank Mono has italics)
      italic-text = "always";
    };
    # Extra syntaxes for file types bat doesn't know about natively.
    # Format: { src = <path to .sublime-syntax file>; }
    # extraSyntaxes = [];
  };

  # ----------------------------------------------------------
  # lazygit — terminal UI for git
  # ----------------------------------------------------------
  # lazygit is a full-featured git TUI: staging hunks, rebasing,
  # stashing, cherry-picking, log browsing — all keyboard-driven.
  # Your old nix-config had this; it pairs very well with neovim
  # (open with <leader>gg from neovim via lazygit.nvim or terminal).
  programs.lazygit = {
    enable = true;
    catppuccin.enable = true;  # applies the official Catppuccin Mocha theme
    settings = {
      # Show file icons (requires Nerd Font — you have Symbols Nerd Font)
      gui.nerdFontsVersion = "3";

      # Keybindings that complement your neovim workflow:
      keybinding.universal = {
        # Scroll diff with ctrl+d/u like neovim
        scrollDownMain-alt1 = "<c-d>";
        scrollUpMain-alt1   = "<c-u>";
      };

      # Confirm before force-pushing to avoid accidents on shared branches
      git.overrideGpg = false;  # let gpg-agent handle commit signing

      # Use delta as the diff pager (configured in git.nix)
      git.paging = {
        colorArg    = "always";
        pager       = "delta --dark --paging=never";
      };
    };
  };

  # ----------------------------------------------------------
  # zathura — PDF/document viewer
  # ----------------------------------------------------------
  # Using the HM module for catppuccin theming.
  # No config file in dotfiles yet, so this is purely nix-managed.
  programs.zathura = {
    enable = true;
    catppuccin.enable = true;
    options = {
      # Fit page width on open
      adjust-open        = "width";
      # Catppuccin Mocha surface colours (catppuccin.enable sets these,
      # but explicit here so you can see what's being controlled)
      # recolor            = true;   # uncomment for forced dark mode recolouring
      selection-clipboard = "clipboard";  # copy selections to system clipboard
    };
  };

  # ----------------------------------------------------------
  # btop — resource monitor (replaces bottom/btm)
  # ----------------------------------------------------------
  # btop is more featureful than bottom and has first-class catppuccin support.
  programs.btop = {
    enable = true;
    catppuccin.enable = true;
    settings = {
      # Show all CPU cores, not just an aggregate
      cpu_single_graph = false;
      # Update interval in milliseconds
      update_ms         = 2000;
      # vim-style navigation
      vim_keys          = true;
      # Round corners (aesthetic)
      rounded_corners   = true;
    };
  };
}
