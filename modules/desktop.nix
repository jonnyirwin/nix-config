{ config, pkgs, ... }:

# ============================================================
# Desktop environment: Sway, Waybar, Rofi, Mako, and friends
# ============================================================
#
# !! IMPORTANT: Debian vs NixOS distinction !!
#
# On NixOS you could use `wayland.windowManager.sway.enable = true` and
# Home Manager would generate the systemd units, set up the session, and
# manage everything. On Debian, Sway is either installed via apt or via
# `home.packages` below, and is launched by your display manager (greetd).
#
# What this module does:
#   • Installs the compositor and its ecosystem tools via `home.packages`
#   • Symlinks your hand-crafted configs from ~/.dotfiles/ so they're
#     active at ~/.config/{sway,waybar,rofi,mako,...}
#
# What this module does NOT do:
#   • Configure systemd user services (Debian manages that separately)
#   • Touch /etc — the greetd setup in your dotfiles' greetd/ dir
#     requires root and is deployed via its own deploy.sh script
# ============================================================

{
  home.packages = with pkgs; [

    # ---- Wayland compositor ----
    sway           # tiling Wayland compositor
    swaybg         # sets the wallpaper (used in your random-wallpaper.sh script)
    swayidle       # triggers actions (lock, suspend) after idle timeout
    swaylock       # screen locker — config symlinked below

    # ---- Status bar ----
    waybar         # highly customisable Wayland bar

    # ---- Application launcher ----
    rofi           # rofi-wayland merged into rofi; Wayland support now built-in

    # ---- Notifications ----
    mako           # Wayland notification daemon — lightweight, scriptable
    # dunst is in your dotfiles but you appear to use mako on Wayland;
    # dunst is an X11 notification daemon. Keep both here if you switch.
    dunst

    # ---- Workspace icons ----
    # sworkstyle renames workspace labels based on the apps in them.
    # Not currently in nixpkgs — install manually if needed.
    # sworkstyle

    # ---- Screenshot / screen recording ----
    grim           # grab regions of the Wayland screen
    slurp          # select regions interactively (piped into grim)
    wf-recorder    # screen recording for Wayland (used in record-toggle.sh)
    satty          # screenshot annotation tool (modern swappy alternative)

    # ---- Clipboard ----
    wl-clipboard   # wl-copy / wl-paste
    cliphist       # clipboard history — integrate with rofi for a history picker

    # ---- Screen color temperature ----
    gammastep      # like f.lux/redshift for Wayland — reduces blue light at night
    # wlsunset is a lighter alternative if gammastep is too heavy

    # ---- OCR (your ocr.sh script uses this) ----
    # Language data is bundled via override; add languages as needed:
    # (tesseract5.override { enableLanguages = [ "eng" "deu" ]; })
    tesseract

    # ---- Fonts ----
    # These complement nerd-fonts.symbols-only in packages.nix.
    # Add font packages here; run `fc-cache -fv` after first switch.
    font-awesome   # icon font used by waybar
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
    # Note: Dank Mono (your kitty font) is proprietary — install manually:
    #   mkdir -p ~/.local/share/fonts && cp DankMono*.otf ~/.local/share/fonts/
    #   fc-cache -fv

    # ---- Fontconfig ----
    fontconfig     # font rendering library — fc-cache, fc-list, etc.

    # ---- Colour picker ----
    hyprpicker     # Wayland colour picker (replaces wcolor-picker/gpick)

    # ---- Display management ----
    wdisplays      # GUI display configurator for wlroots compositors (like arandr for Wayland)
    kanshi         # automatic display profile switching (like autorandr for Wayland)

    # ---- Audio ----
    pulsemixer     # TUI PulseAudio mixer — your dotfiles have its config
    playerctl      # MPRIS media player controller (waybar integration)
    pamixer        # PulseAudio CLI volume control

    # ---- Idle and power ----
    wlopm          # wlr-output-power-management — turn displays off/on
  ];

  # ----------------------------------------------------------
  # Sway configuration
  # ----------------------------------------------------------
  # Sway is configured entirely through the config files in your dotfiles.
  # The main config and config.d/ snippets are symlinked here.
  xdg.configFile."sway/config".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/sway/.config/sway/config";

  xdg.configFile."sway/config.d".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/sway/.config/sway/config.d";

  xdg.configFile."sway/scripts".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/sway/.config/sway/scripts";

  xdg.configFile."sway/hosts".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/sway/.config/sway/hosts";

  # ----------------------------------------------------------
  # Waybar
  # ----------------------------------------------------------
  xdg.configFile."waybar/style.css".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/waybar/.config/waybar/style.css";

  xdg.configFile."waybar/mocha.css".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/waybar/.config/waybar/mocha.css";

  xdg.configFile."waybar/restart.sh".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/waybar/.config/waybar/restart.sh";

  # ----------------------------------------------------------
  # Rofi launcher
  # ----------------------------------------------------------
  xdg.configFile."rofi/config.rasi".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/rofi/.config/rofi/config.rasi";

  xdg.configFile."rofi/catppuccin-mocha.rasi".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/rofi/.config/rofi/catppuccin-mocha.rasi";

  xdg.configFile."rofi/catppuccin-default.rasi".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/rofi/.config/rofi/catppuccin-default.rasi";

  # ----------------------------------------------------------
  # Mako (Wayland notification daemon)
  # ----------------------------------------------------------
  xdg.configFile."mako/config".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/mako/.config/mako/config";

  # ----------------------------------------------------------
  # Fontconfig
  # ----------------------------------------------------------
  xdg.configFile."fontconfig/fonts.conf".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/fontconfig/.config/fontconfig/fonts.conf";

  # ----------------------------------------------------------
  # Swaylock
  # ----------------------------------------------------------
  # swaylock config (if you have one in your dotfiles swaylock/ directory)
  # xdg.configFile."swaylock/config".source = config.lib.file.mkOutOfStoreSymlink
  #   "${config.home.homeDirectory}/.dotfiles/swaylock/.config/swaylock/config";

  # ----------------------------------------------------------
  # Yazi file manager
  # ----------------------------------------------------------
  xdg.configFile."yazi/yazi.toml".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/yazi/.config/yazi/yazi.toml";

  xdg.configFile."yazi/keymap.toml".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/yazi/.config/yazi/keymap.toml";

  xdg.configFile."yazi/theme.toml".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/yazi/.config/yazi/theme.toml";

  # ----------------------------------------------------------
  # Pulsemixer
  # ----------------------------------------------------------
  xdg.configFile."pulsemixer.cfg".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/pulsemixer/.config/pulsemixer.cfg";

  # ----------------------------------------------------------
  # Zathura PDF viewer
  # ----------------------------------------------------------
  # If you add a zathurarc to your dotfiles, uncomment:
  # xdg.configFile."zathura/zathurarc".source = config.lib.file.mkOutOfStoreSymlink
  #   "${config.home.homeDirectory}/.dotfiles/zathura/.config/zathura/zathurarc";

  # ----------------------------------------------------------
  # GTK theming (optional but consistent with Catppuccin)
  # ----------------------------------------------------------
  gtk = {
    enable = true;
    theme = {
      name    = "Catppuccin-Mocha-Standard-Mauve-Dark";
      # Install the package:
      # package = pkgs.catppuccin-gtk.override { accents = ["mauve"]; variant = "mocha"; };
    };
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name    = "Catppuccin-Mocha-Mauve-Cursors";
      size    = 24;
      # package = pkgs.catppuccin-cursors.mochaMauve;
    };
  };
}
