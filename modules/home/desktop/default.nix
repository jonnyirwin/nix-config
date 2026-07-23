{ lib, ... }:

{
  imports = [
    ./scripts.nix
    ./pomodoro.nix
    ./sway.nix
    ./waybar.nix
    ./rofi.nix
    ./mako.nix
    ./swaylock.nix
    ./fonts.nix
    ./gtk.nix
    ./packages.nix
  ];

  options.jonny.desktop = {
    enable = lib.mkEnableOption "the Sway desktop user environment";

    outputs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
      example = lib.literalExpression ''
        { "DP-1" = { resolution = "2560x1440"; transform = "90"; }; }
      '';
      description = ''
        Sway output configuration, per host. This replaces the runtime-generated
        config.d/display-settings.conf that resolution-switcher.sh used to write:
        permanent layout belongs here, ad-hoc changes go through wdisplays
        (Mod+Shift+D) and should be folded back into this option.
      '';
    };

    extraKeybindings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Host-specific sway keybindings, merged over the shared set.";
    };
  };
}
