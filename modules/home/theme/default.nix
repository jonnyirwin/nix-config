{ config, lib, pkgs, osConfig ? { }, ... }:

let
  cfg = config.jonny.theme;
  myLib = import ../../../lib { inherit lib; };

  # The host declares its theme once, at the system level
  # (modules/nixos/theme.nix), because SDDM needs it before any Home Manager
  # profile exists. These options default from there so a host does not repeat
  # itself — and can still override, for a user whose session should not match
  # the greeter.
  #
  # `or` rather than a plain lookup: osConfig is absent when this module tree is
  # consumed as homeModules.default from a standalone Home Manager setup, where
  # there is no NixOS config to read.
  osTheme = osConfig.jonny.theme or { };

  catppuccinFlavor = myLib.catppuccinFlavors.${cfg.scheme} or null;

  fontType = lib.types.submodule {
    options = {
      family = lib.mkOption {
        type = lib.types.str;
        description = "Family name as fontconfig sees it.";
      };

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = ''
          Package providing the family, installed automatically. Null for
          fonts installed by hand (proprietary ones) or already provided
          system-wide.
        '';
      };

      size = lib.mkOption {
        type = lib.types.int;
        description = "Point size.";
      };
    };
  };
in
{
  options.jonny.theme = {
    scheme = lib.mkOption {
      type = lib.types.enum myLib.schemeNames;
      default = osTheme.scheme or "catppuccin-mocha";
      defaultText = lib.literalExpression "osConfig.jonny.theme.scheme";
      description = ''
        Colour scheme, inherited from the host's system-level jonny.theme.scheme
        unless overridden here. Every module renders from `palette` below rather than
        naming a scheme, so changing this one line re-themes sway, waybar,
        rofi, mako, swaylock, kitty, fzf, starship and tmux together.

        Schemes live in lib/schemes/ and all expose the same key set; adding
        one is a file plus a line in lib/schemes/default.nix.
      '';
    };

    accent = lib.mkOption {
      type = lib.types.enum myLib.accentNames;
      default = osTheme.accent or "purple";
      defaultText = lib.literalExpression "osConfig.jonny.theme.accent";
      description = ''
        The focus colour, inherited from the host's system-level
        jonny.theme.accent unless overridden here. Chosen by hue rather than by a scheme's brand name
        for a colour — so "purple" means the same thing in every scheme and
        survives switching. Drives sway borders, the waybar focused workspace
        pill, the swaylock ring, rofi selection, and mako's summary text.
      '';
    };

    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      readOnly = true;
      default = myLib.schemes.${cfg.scheme} // {
        accent = myLib.schemes.${cfg.scheme}.hues.${cfg.accent};
      };
      description = ''
        The active scheme, plus `accent` resolved from `jonny.theme.accent`.

        Modules should read semantic roles (bg, surface, fg, border, error,
        warning, success, info) wherever the colour has a meaning, and fall
        back to `hues.*` only where the point is to have several visually
        distinct colours. See lib/schemes/default.nix.
      '';
    };

    fonts = {
      mono = lib.mkOption {
        type = fontType;
        default = {
          family = "Dank Mono";
          package = null; # proprietary; installed by hand
          size = 16;
        };
        description = "Terminal and editor font.";
      };

      ui = lib.mkOption {
        type = fontType;
        default = {
          family = "Dank Mono";
          package = null;
          size = 14;
        };
        description = "Bar, notification and launcher font.";
      };

      fallback = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "Symbols Nerd Font Mono" "Noto Color Emoji" "DejaVu Sans Mono" ];
        description = ''
          Appended after the chosen family wherever a font stack is written
          (waybar CSS, kitty). Icon coverage is declared once here rather than
          repeated per module.
        '';
      };

      substitute = lib.mkOption {
        type = lib.types.nullOr fontType;
        default = {
          family = "Intel One Mono";
          package = pkgs.intel-one-mono;
          size = 16;
        };
        description = ''
          Stand-in for `mono.family` when it is not installed, wired up as a
          fontconfig alias in desktop/fonts.nix. Dank Mono is proprietary and
          hand-installed, so a fresh machine has nothing until you copy the
          .otf files in; the alias means every config can name it
          unconditionally and still render. Null disables the alias.
        '';
      };
    };
  };

  config = {
    # catppuccin/nix themes programs that have upstream support. It can only
    # produce Catppuccin, so for any other scheme it is switched off entirely
    # and those programs are themed from the palette instead.
    catppuccin = {
      enable = catppuccinFlavor != null;
      autoEnable = false;
    } // lib.optionalAttrs (catppuccinFlavor != null) {
      flavor = catppuccinFlavor;
      # Translated back into Catppuccin's own accent vocabulary.
      accent = myLib.catppuccinAccents.${cfg.accent};
    };

    # Font packages follow the declaration instead of being listed separately.
    home.packages = lib.filter (p: p != null) [
      cfg.fonts.mono.package
      cfg.fonts.ui.package
      (if cfg.fonts.substitute == null then null else cfg.fonts.substitute.package)
    ];
  };
}
