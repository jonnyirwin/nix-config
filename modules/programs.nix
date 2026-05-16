{ config, pkgs, ... }:

# ============================================================
# Programs with catppuccin/nix theming
# ============================================================
#
# catppuccin/nix integration (new API)
# ─────────────────────────────────────
# The module adds a top-level `catppuccin` namespace — NOT sub-options
# under `programs.<name>`. The pattern is:
#
#   catppuccin.<program>.enable = true;
#
# The global `catppuccin.flavor` and `catppuccin.accent` in home.nix
# cascade to all programs automatically. Per-program overrides:
#   catppuccin.bat.flavor = "latte";
# ============================================================

{
  # ----------------------------------------------------------
  # bat — cat replacement with syntax highlighting
  # ----------------------------------------------------------
  catppuccin.bat.enable = true;

  programs.bat = {
    enable = true;
    config = {
      style       = "numbers,changes,header";
      italic-text = "always";
    };
  };

  # ----------------------------------------------------------
  # lazygit — terminal UI for git
  # ----------------------------------------------------------
  catppuccin.lazygit.enable = true;

  programs.lazygit = {
    enable = true;
    settings = {
      gui.nerdFontsVersion = "3";

      keybinding.universal = {
        scrollDownMain-alt1 = "<c-d>";
        scrollUpMain-alt1   = "<c-u>";
      };

      git.overrideGpg = false;

      git.paging = {
        colorArg = "always";
        pager    = "delta --dark --paging=never";
      };
    };
  };

  # ----------------------------------------------------------
  # zathura — PDF/document viewer
  # ----------------------------------------------------------
  catppuccin.zathura.enable = true;

  programs.zathura = {
    enable = true;
    options = {
      adjust-open         = "width";
      selection-clipboard = "clipboard";
    };
  };

  # ----------------------------------------------------------
  # btop — resource monitor
  # ----------------------------------------------------------
  catppuccin.btop.enable = true;

  programs.btop = {
    enable = true;
    settings = {
      cpu_single_graph = false;
      update_ms        = 2000;
      vim_keys         = true;
      rounded_corners  = true;
    };
  };
}
