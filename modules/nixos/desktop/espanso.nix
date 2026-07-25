{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Espanso's Wayland backend types by injecting events through a virtual
    # input device (evdev), which needs write access to /dev/uinput. This
    # module (kernel module + udev rule + "uinput" group) is what grants
    # that; modules/nixos/core/users.nix adds jonny to the group.
    hardware.uinput.enable = true;
  };
}
