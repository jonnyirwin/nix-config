{ lib, config, osConfig ? { }, ... }:

let
  cfg = config.jonny.desktop;

  # Defaults come from the host's system-level jonny.desktop, so enabling the
  # desktop and picking a compositor is stated once per host rather than twice.
  # See the same pattern in modules/home/theme/default.nix for why `or` is used.
  osDesktop = osConfig.jonny.desktop or { };
in
{
  imports = [
    # ---- Compositor-agnostic ----
    ./actions.nix
    ./scripts.nix
    ./command-menu.nix
    ./pomodoro.nix
    ./waybar.nix
    ./rofi.nix
    ./mako.nix
    ./quickshell
    ./fonts.nix
    ./gtk.nix
    ./qt.nix
    ./packages.nix
    ./aseprite.nix
    ./pico8.nix
    ./espanso.nix
    ./wallpaper.nix
    ./kitty.nix
    ./zathura.nix
    ./storage.nix
    ./gammastep.nix

    # ---- Compositor-specific ----
    # Each gates itself on jonny.desktop.compositor, so adding a second one is
    # a new file plus an enum value — nothing here or in the shared modules
    # changes.
    ./compositors/sway.nix
    ./compositors/swaylock.nix
  ];

  options.jonny.desktop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = osDesktop.enable or false;
      defaultText = lib.literalExpression "osConfig.jonny.desktop.enable";
      description = ''
        Whether to configure the graphical desktop user environment. Follows the
        host's system-level jonny.desktop.enable unless overridden here.
      '';
    };

    compositor = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "sway" ]);
      default = osDesktop.compositor or null;
      defaultText = lib.literalExpression "osConfig.jonny.desktop.compositor";
      description = ''
        Which Wayland compositor to configure, inherited from the host's
        system-level jonny.desktop.compositor. Everything that is not
        compositor-specific — bar, launcher, notifications, theme, fonts,
        scripts — is shared, so switching this should not require touching
        anything else.
      '';
    };

    shell = lib.mkOption {
      type = lib.types.enum [ "waybar" "quickshell" ];
      default = "waybar";
      description = ''
        Which UI stack owns the bar, app launcher and notifications.

        "waybar" is waybar.nix + rofi's drun mode + mako — the stable,
        long-running setup. "quickshell" is the experimental replacement in
        ./quickshell: a from-scratch QML shell (bar, launcher, notification
        toasts, volume/brightness OSD, quick-settings panel), themed from
        the same jonny.theme.palette.

        waybar.nix and mako.nix gate their own `config` on this so the two
        never both try to own the top bar or the notification bus at once;
        rofi.nix does not, since scripts.nix uses plain rofi -dmenu as a
        generic picker independently of which shell owns app launching.
      '';
    };

    # Read by waybar (workspace module, systemd target) and by anything else
    # that needs to vary by compositor without hardcoding a name.
    sessionTarget = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${cfg.compositor}-session.target";
      description = "The systemd user target the compositor's session binds to.";
    };

    outputs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
      example = lib.literalExpression ''
        { "DP-1" = { resolution = "2560x1440"; transform = "90"; }; }
      '';
      description = ''
        Display configuration, per host. This replaces the runtime-generated
        config.d/display-settings.conf that resolution-switcher.sh used to
        write: permanent layout belongs here, ad-hoc changes go through
        wdisplays (Mod+Shift+D) and should be folded back into this option.
      '';
    };

    extraKeybindings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Host-specific keybindings, merged over the shared set.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.compositor != null;
        message = "jonny.desktop.enable requires jonny.desktop.compositor to be set.";
      }
    ];
  };
}
