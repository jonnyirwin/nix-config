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

    # ---- Terminal ----
    kitty          # GPU-accelerated terminal emulator

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
    font-awesome              # icon font used by waybar
    intel-one-mono            # terminal font
    nerd-fonts.jetbrains-mono # nerdfonts was split into individual packages
    nerd-fonts.fira-code

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
  # Dotfiles config symlinks
  # ----------------------------------------------------------
  # Each entry symlinks the ENTIRE app config directory from dotfiles.
  # This means any file you add to dotfiles is automatically live —
  # no need to add individual symlinks here when you add new scripts
  # or config fragments.

  # Sway — whole config dir (includes config, config.d/, scripts/, hosts/, etc.)
  xdg.configFile."sway".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/sway/.config/sway";

  # Waybar — whole config dir (includes config/config.jsonc, style.css, scripts/, etc.)
  xdg.configFile."waybar".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/waybar/.config/waybar";

  # Rofi — whole config dir (includes config.rasi, themes/, scripts/, etc.)
  xdg.configFile."rofi".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/rofi/.config/rofi";

  # Kitty terminal — whole config dir
  xdg.configFile."kitty".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/kitty/.config/kitty";

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
    gtk4.theme = config.gtk.theme; # silence HM 26.05 migration warning; keeps legacy mirroring behaviour
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
