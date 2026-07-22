{ config, pkgs, ... }:

# ============================================================
# Terminal emulator
# ============================================================
#
# Kitty is symlinked from your dotfiles rather than configured via the
# HM module, because:
#
#   1. Your config is already mature and well-tuned.
#   2. The HM kitty module would require translating every colour
#      value and keybinding into Nix attrs — more friction than benefit.
#   3. A live symlink means you can tweak kitty.conf and reload (Ctrl+Shift+F5)
#      without running `home-manager switch`.
#
# Tmux does NOT work this way — see modules/tmux.nix, which builds the whole
# config (and its plugins) from the store via programs.tmux.
#
# What Nix DOES manage here: installing the binary. On Debian you could also
# install it via apt, but using Nix means you get a consistent, up-to-date
# version that doesn't depend on Debian's slower package cycle.
# ============================================================

{
  home.packages = with pkgs; [
    # ---- Kitty ----
    kitty          # GPU-accelerated terminal — your primary terminal
  ];

  # ----------------------------------------------------------
  # Kitty config symlink
  # ----------------------------------------------------------
  # ~/.config/kitty/kitty.conf → ~/.dotfiles/kitty/.config/kitty/kitty.conf
  xdg.configFile."kitty/kitty.conf".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/kitty/.config/kitty/kitty.conf";

  # The .terminfo entry in your dotfiles tells the system how to handle
  # kitty's terminal type ("xterm-kitty"). Without it, SSH sessions and
  # some tools won't render correctly.
  xdg.configFile."kitty/.terminfo".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/kitty/.terminfo";
}
