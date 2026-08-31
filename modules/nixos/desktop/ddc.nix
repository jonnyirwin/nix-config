{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.desktop;
in
{
  # DDC/CI: brightness (and contrast, and input source) on an external monitor,
  # over the i2c bus that runs alongside the video signal in the cable. This is
  # what the desktops have instead of /sys/class/backlight, which only ever
  # exists for a laptop's own panel — without it the brightness keys are dead on
  # every host but mac and precision, and the adjustment lives on the monitor's
  # front buttons.
  #
  # The user-facing half is the `brightness` script in
  # modules/home/desktop/scripts.nix, bound to Mod+Alt+L/H.
  config = lib.mkIf cfg.enable {
    # Loads i2c-dev and creates the `i2c` group with a udev rule granting it
    # the /dev/i2c-* nodes. Without the module there are no nodes at all, and
    # without the group ddcutil needs root.
    hardware.i2c.enable = true;
    users.users.jonny.extraGroups = [ "i2c" ];

    # Not needed by the script — that pins its own copy via runtimeInputs — but
    # `ddcutil detect` is the first thing to reach for when a monitor does not
    # respond, so it is worth having by hand.
    environment.systemPackages = [ pkgs.ddcutil ];
  };
}
