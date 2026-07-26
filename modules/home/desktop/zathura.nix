{ config, lib, ... }:

# PDF viewer. A graphical application, so it follows the desktop gate rather
# than living with the terminal-based tools — see the note in kitty.nix.
let
  cfg = config.jonny.desktop;
in
{
  catppuccin.zathura.enable = cfg.enable;

  programs.zathura = lib.mkIf cfg.enable {
    enable = true;
    options = {
      adjust-open = "width";
      selection-clipboard = "clipboard";
    };
  };
}
