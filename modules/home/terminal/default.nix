# Terminal-based tools — TUI, no display server required, so these are
# unconditional and a headless host gets them too.
#
# The terminal *emulator* (kitty) and the PDF viewer (zathura) used to live
# here. They draw windows, so they moved to modules/home/desktop/ and follow
# jonny.desktop.enable.
{
  imports = [
    ./tmux.nix
    ./yazi.nix
    ./bat.nix
    ./btop.nix
    ./lazygit.nix
    ./rss-is-terminal.nix
  ];
}
