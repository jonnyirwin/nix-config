{ config, pkgs, lib, ... }:

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
    rofimoji       # emoji/char picker for rofi (emoji-picker.sh prefers it)

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
    pulseaudio     # provides `pactl` (audio-output.sh / audio-switch.sh); client
                   # tools work fine against PipeWire's pulse shim


    # ---- Idle and power ----
    wlopm          # wlr-output-power-management — turn displays off/on
  ];

  # ----------------------------------------------------------
  # Dotfiles config symlinks (via home.activation)
  # ----------------------------------------------------------
  # xdg.configFile with a directory source fails in the NixOS HM module
  # sandbox — the builder can't access paths outside the nix store.
  # home.activation runs after the sandbox build, as the real user,
  # so it can safely create symlinks to dotfiles directories.
  # Each link is a no-op if the dotfiles aren't cloned yet, or if the
  # symlink already exists.
  home.activation.dotfilesSymlinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _dot="${config.home.homeDirectory}/.dotfiles"
    _cfg="${config.xdg.configHome}"

    _link() {
      local src="$1" dst="$2"
      # Use `if` (not `a && b && c`): when the symlink already exists the guard
      # is false, and a bare `&&` chain would make the function return 1 —
      # aborting activation under `set -e` on every rebuild after the first.
      if [ -d "$src" ] && [ ! -e "$dst" ]; then
        ln -s "$src" "$dst"
      fi
      return 0
    }

    _link "$_dot/sway/.config/sway"             "$_cfg/sway"
    _link "$_dot/waybar/.config/waybar"         "$_cfg/waybar"
    _link "$_dot/rofi/.config/rofi"             "$_cfg/rofi"
    _link "$_dot/kitty/.config/kitty"           "$_cfg/kitty"
    _link "$_dot/mako/.config/mako"             "$_cfg/mako"
    _link "$_dot/yazi/.config/yazi"             "$_cfg/yazi"
    # NOTE: fontconfig is deliberately *not* linked here. home-manager's own
    # fonts.fontconfig module writes into ~/.config/fontconfig/conf.d, so the
    # directory always exists by activation time and `_link`'s `! -e` guard
    # never fires. Our rules live in the nix-managed conf.d drop-in below.
  '';

  # (mako, yazi, kitty, rofi, sway, waybar symlinks are all
  #  handled by home.activation.dotfilesSymlinks above)

  # ----------------------------------------------------------
  # Fontconfig — Dank Mono with an Intel One Mono fallback
  # ----------------------------------------------------------
  # Dank Mono is proprietary and installed by hand (see modules/packages.nix),
  # so it is absent on a fresh machine. The alias lets kitty.conf say
  # `font_family Dank Mono` unconditionally: fontconfig returns Dank Mono when
  # it is present and falls through to Intel One Mono when it is not.
  #
  # Numbered 09- so the target="scan" rule is registered before fontconfig
  # scans the font directories; the alias would work at any number.
  xdg.configFile."fontconfig/conf.d/09-dank-mono.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Dank Mono Italic ships without a spacing property, which makes kitty
           reject it as non-monospace. Force it. -->
      <match target="scan">
        <test name="family"><string>Dank Mono</string></test>
        <test name="style"><string>Italic</string></test>
        <edit name="spacing"><int>100</int></edit>
      </match>

      <!-- binding="same" appends rather than replaces: Dank Mono still wins
           outright when installed. -->
      <alias binding="same">
        <family>Dank Mono</family>
        <prefer><family>Intel One Mono</family></prefer>
      </alias>
    </fontconfig>
  '';

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

  # ----------------------------------------------------------
  # Firefox + 1Password extension
  # ----------------------------------------------------------
  # Firefox is managed here (rather than a bare package in packages.nix)
  # so enterprise policies apply. ExtensionSettings force-installs the
  # 1Password extension from AMO onto every profile — no manual install.
  # It pairs with the 1Password desktop app enabled at the system level
  # (programs._1password-gui in nixos-modules/desktop.nix) which provides
  # the native-messaging bridge the extension uses to unlock.
  programs.firefox = {
    enable = true;
    # Adopt the new XDG default explicitly (the HM default only flips to this at
    # stateVersion 26.05). Your actual profile already lives here
    # (~/.config/mozilla/firefox), so this aligns HM with reality — no data move.
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    policies.ExtensionSettings = {
      # 1Password – Password Manager
      "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
        installation_mode = "force_installed";
      };
    };
  };
}
