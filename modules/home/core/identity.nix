{ config, ... }:

{
  home = {
    username = "jonny";
    homeDirectory = "/home/jonny";

    # Controls backwards-compatibility shims inside Home Manager itself.
    # Set once at first install; changing it silently changes defaults.
    stateVersion = "24.11";

    # Directories Home Manager will not create on its own.
    file."Pictures/Screenshots/.keep".text = "";
    file."Pictures/Wallpapers/.keep".text = "";

    sessionVariables = {
      XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
    };
  };

  # Write to ~/.config, ~/.local/share, ~/.cache rather than the home root.
  xdg.enable = true;

  programs.home-manager.enable = true;
}
