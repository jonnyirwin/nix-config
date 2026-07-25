{ lib, config, pkgs, ... }:

# SDDM — graphical, Wayland-native login screen, Catppuccin-themed via
# catppuccin/nix's NixOS module. Replaces the previous greetd + tuigreet
# (TUI) setup.
#
# jonny.theme here is a system-level counterpart to the Home Manager option
# of the same name (modules/home/theme/default.nix): SDDM runs before any
# user's Home Manager profile is activated, so it cannot read that option,
# and catppuccin/nix's NixOS and Home Manager modules are independent of each
# other. Set both to the same scheme/accent on a host; they don't sync
# automatically.
let
  cfg = config.jonny.desktop;
  themeCfg = config.jonny.theme;
  myLib = import ../../../lib { inherit lib; };
  catppuccinFlavor = myLib.catppuccinFlavors.${themeCfg.scheme} or null;

  greeter = cfg.greeter;

  # SDDM's Wayland greeter runs weston (--shell=kiosk); weston reads its output
  # rotation from a weston.ini [output] block keyed by connector name. This is
  # the same wl_output transform sway uses in jonny.desktop.outputs, so a
  # portrait panel needs the greeter set to match — SDDM runs before any Home
  # Manager profile, so it can't read that option and gets told here instead.
  #
  # Translating the sway-style transform to weston needs two fixes, both learnt
  # the hard way on this panel:
  #
  #   1. Spelling. sway takes "90"; weston takes "rotate-90". A bare "90" gives
  #      `Invalid transform "90"` → `Could not enable any output` → a black
  #      greeter that never hands off to SDDM.
  #
  #   2. Direction. weston rotates the *opposite* way to sway/wlroots for the
  #      same nominal angle, so a sway `transform 90` session matched to a
  #      weston `rotate-90` greeter comes out 180° apart — upside down. Inverting
  #      the angle (90 → rotate-270, 270 → rotate-90) lines them up.
  swayToWeston = {
    "normal" = "normal";
    "90" = "rotate-270";
    "180" = "rotate-180";
    "270" = "rotate-90";
  };
  westonTransform = swayToWeston.${greeter.transform};
  westonIni = (pkgs.formats.ini { }).generate "weston.ini" {
    # Keep the greeter's password prompt on the same keymap as the session.
    keyboard.keymap_layout = "gb";
    output = {
      name = greeter.output;
      transform = westonTransform;
    };
  };
  compositorCommand = "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
in
{
  options.jonny.desktop.greeter = {
    output = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "DP-1";
      description = ''
        DRM connector the SDDM greeter should rotate (e.g. "DP-1"). Leave null
        to use weston's default (unrotated). Must match the connector name sway
        uses in jonny.desktop.outputs on the same host.
      '';
    };

    transform = lib.mkOption {
      type = lib.types.enum [ "normal" "90" "180" "270" ];
      default = "normal";
      description = ''
        wl_output transform for the greeter output, matching the value in
        jonny.desktop.outputs. Only applied when greeter.output is set.
      '';
    };
  };

  options.jonny.theme = {
    scheme = lib.mkOption {
      type = lib.types.enum myLib.schemeNames;
      default = "catppuccin-mocha";
      description = "System-level theme scheme, used to theme SDDM.";
    };

    accent = lib.mkOption {
      type = lib.types.enum myLib.accentNames;
      default = "purple";
      description = "System-level accent, used to theme SDDM. Named by hue — see jonny.theme.accent on the Home Manager side.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm = {
      enable = true;
      # No Xorg is configured anywhere in this repo — sway is Wayland-only —
      # so the greeter itself needs to run under Wayland too.
      wayland.enable = true;

      # Only override weston's command when a rotation is actually requested;
      # otherwise leave the module's stock compositor command untouched.
      wayland.compositorCommand = lib.mkIf (greeter.output != null) compositorCommand;
    };

    catppuccin = lib.mkIf (catppuccinFlavor != null) {
      # sddm.nix's own gate is `catppuccin.enable && catppuccin.sddm.enable`,
      # so the global switch has to be on — but leaving autoEnable at its
      # default would auto-theme every other catppuccin/nix NixOS module too
      # (tty console colours, grub, gtk...). Opt in to just sddm.
      enable = true;
      autoEnable = false;
      flavor = catppuccinFlavor;
      accent = myLib.catppuccinAccents.${themeCfg.accent};
      sddm.enable = true;
    };
  };
}
