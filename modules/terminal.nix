{ config, pkgs, ... }:

# ============================================================
# Terminal emulator and multiplexer
# ============================================================
#
# Kitty and Tmux are both symlinked from your dotfiles rather than
# configured via HM modules, because:
#
#   1. Your configs are already mature and well-tuned.
#   2. The HM kitty module would require translating every colour
#      value and keybinding into Nix attrs — more friction than benefit.
#   3. Live symlinks mean you can tweak kitty.conf and reload (Ctrl+Shift+F5)
#      without running `home-manager switch`.
#
# What Nix DOES manage: installing the binaries. On Debian you could also
# install these via apt, but using Nix means you get a consistent, up-to-date
# version that doesn't depend on Debian's slower package cycle.
# ============================================================

{
  home.packages = with pkgs; [
    # ---- Kitty ----
    kitty          # GPU-accelerated terminal — your primary terminal

    # ---- Tmux ----
    tmux           # terminal multiplexer

    # Tmux plugins are managed by tpm (Tmux Plugin Manager), which you
    # already have set up via your dotfiles. Nix doesn't manage tpm plugins
    # because tpm clones them into ~/.tmux/plugins/ at runtime, which
    # works perfectly with the symlinked tmux.conf.
    #
    # To install tpm plugins after a fresh clone: prefix + I (capital i)
    # To update: prefix + U

    # ---- Dependencies used by tmux/kitty scripts ----
    wl-clipboard   # wl-copy (used in your tmux copy-mode bindings)
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

  # ----------------------------------------------------------
  # Tmux config symlink
  # ----------------------------------------------------------
  # ~/.config/tmux/tmux.conf → ~/.dotfiles/tmux/.config/tmux/tmux.conf
  xdg.configFile."tmux/tmux.conf".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/tmux/.config/tmux/tmux.conf";

  # Symlink the tmux plugins directory (catppuccin, tpm, resurrect, etc.)
  # This avoids having to run `tpm install` after every fresh checkout.
  xdg.configFile."tmux/plugins".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/tmux/.config/tmux/plugins";
}
