{ lib, config, pkgs, ... }:

# SDDM — graphical, Wayland-native login screen, Catppuccin-themed via
# catppuccin/nix's NixOS module. Replaces the previous greetd + tuigreet
# (TUI) setup.
#
# The scheme comes from jonny.theme (modules/nixos/theme.nix), which the Home
# Manager side also defaults from — so the greeter and the session cannot drift
# apart. SDDM needs the system-level option because it runs before any user's
# Home Manager profile is activated, and catppuccin/nix's NixOS and Home
# Manager modules are independent of each other.
let
  cfg = config.jonny.desktop;
  themeCfg = config.jonny.theme;
  myLib = import ../../../lib { inherit lib; };
  catppuccinFlavor = myLib.catppuccinFlavors.${themeCfg.scheme} or null;

  inherit (cfg) greeter;

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

  # The keymap is unconditional; the output block is not. These used to be one
  # attrset behind a single `greeter.output != null` gate, which quietly tied
  # the keyboard layout to whether a rotation happened to be configured — drop
  # the rotation and the greeter's password prompt silently reverted to
  # weston's stock US, while the session stayed on GB.
  westonIni = (pkgs.formats.ini { }).generate "weston.ini" ({
    # Keep the greeter's password prompt on the same keymap as the session.
    keyboard.keymap_layout = "gb";
  } // lib.optionalAttrs (greeter.output != null) {
    output = {
      name = greeter.output;
      transform = westonTransform;
    };
  });
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

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm = {
      enable = true;
      # No Xorg is configured anywhere in this repo — sway is Wayland-only —
      # so the greeter itself needs to run under Wayland too.
      wayland.enable = true;

      # Always ours: the generated weston.ini carries the greeter's keymap
      # whether or not there is a rotation to apply (see westonIni above).
      wayland.compositorCommand = compositorCommand;
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
