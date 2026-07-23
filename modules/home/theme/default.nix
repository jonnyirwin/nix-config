{ config, lib, ... }:

let
  cfg = config.jonny.theme;
  myLib = import ../../../lib { inherit lib; };
in
{
  options.jonny.theme = {
    flavor = lib.mkOption {
      type = lib.types.enum myLib.flavorNames;
      default = "mocha";
      description = "Catppuccin flavour used across every themed program.";
    };

    accent = lib.mkOption {
      type = lib.types.enum myLib.accentNames;
      default = "mauve";
      description = ''
        The focus colour. Drives sway borders, the waybar focused workspace pill,
        the swaylock ring, rofi selection, and mako's summary text.
      '';
    };

    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = myLib.palettes.${cfg.flavor} // {
        accent = myLib.palettes.${cfg.flavor}.${cfg.accent};
      };
      description = ''
        Raw hex values for the selected flavour, plus `accent` resolved from
        `jonny.theme.accent`. Read this in any module that writes colours itself.
      '';
    };

    font = {
      family = lib.mkOption {
        type = lib.types.str;
        default = "Dank Mono";
        description = ''
          Primary UI/terminal font. Dank Mono is proprietary and installed by
          hand; modules/home/desktop/fonts.nix aliases it to Intel One Mono via
          fontconfig so this name always resolves.
        '';
      };

      size = lib.mkOption {
        type = lib.types.int;
        default = 14;
      };
    };
  };

  config = {
    # catppuccin/nix themes programs with upstream support. Keep autoEnable off
    # and opt in per program: auto-enrolment would fight the explicit palette
    # values we write ourselves in sway/waybar/rofi/mako.
    catppuccin = {
      enable = true;
      autoEnable = false;
      inherit (cfg) flavor accent;
    };
  };
}
