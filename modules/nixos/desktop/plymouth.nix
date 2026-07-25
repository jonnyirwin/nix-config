{ lib, config, ... }:

# Plymouth — the graphical boot splash, and (the reason it earns its keep here)
# a graphical LUKS passphrase prompt in place of the bare console one.
#
# The graphical prompt is not Plymouth on its own: it needs a systemd-driven
# initrd (boot.initrd.systemd.enable), because that is what runs the
# systemd-cryptsetup password agent Plymouth draws. disko emits
# boot.initrd.luks.devices.cryptroot from hosts/optiplex/disks/nvme.nix, and
# NixOS translates that into the systemd-cryptsetup unit automatically — so
# enabling systemd-initrd is the whole switch, no crypttab wiring by hand.
#
# Themed via catppuccin/nix, matching the SDDM greeter (modules/nixos/desktop/
# sddm.nix owns the shared catppuccin.{flavor,accent}); the theme stays inert
# on non-catppuccin schemes because its gate is catppuccin.enable &&
# catppuccin.plymouth.enable, and the former is only on for catppuccin schemes.
#
# Rotation caveat: the `video=<connector>:rotate=<deg>` kernel param below
# rotates the DRM *fbcon* text console — the emergency TTY — which is worth
# having on a portrait panel. It does NOT rotate Plymouth itself: Plymouth
# drives KMS directly with its own framebuffers rather than going through
# drm_fb_helper, so it ignores the cmdline rotation. There is no clean way to
# rotate Plymouth's splash or its LUKS passphrase prompt on an external monitor
# (the panel_orientation quirk only covers built-in panels). So the boot splash
# and password prompt stay landscape; the session (sway) and the greeter
# (weston, modules/nixos/desktop/sddm.nix) are the parts that actually rotate.
let
  cfg = config.jonny.desktop;
  g = cfg.greeter;
  # Rotates the fbcon console only — see the caveat above. Reuses the greeter
  # transform so the console matches the session's orientation.
  rotateParam = lib.optional (g.output != null && g.transform != "normal")
    "video=${g.output}:rotate=${g.transform}";
in
{
  config = lib.mkIf cfg.enable {
    boot = {
      plymouth.enable = true;

      # Graphical LUKS prompt (see the header) — also the modern, better-
      # supported initrd path generally.
      initrd.systemd.enable = true;

      # A clean splash instead of a wall of kernel/udev logs. The passphrase
      # prompt still interrupts the splash when the disk needs unlocking.
      kernelParams = [ "quiet" "udev.log_level=3" ] ++ rotateParam;
      consoleLogLevel = 0;
      initrd.verbose = false;
    };

    catppuccin.plymouth.enable = true;
  };
}
