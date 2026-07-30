{ pkgs, ... }:

{
  users.users.jonny = {
    isNormalUser = true;
    description = "Jonny Irwin";
    # uinput: espanso's Wayland backend types via a virtual input device —
    # see modules/nixos/desktop/espanso.nix for the matching udev rule.
    # dialout: read/write on /dev/ttyUSB* and /dev/ttyACM*, without which tio
    # and PlatformIO cannot talk to a board.
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "uinput" "dialout" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6XbyUKquA4YBu3pKfFlOrDOIIbrj7o4tYpWFZ+3NOV"
    ];
  };

  # Fish must be enabled system-wide so /etc/shells lists it — otherwise it is
  # not a valid login shell, whatever users.users.jonny.shell says.
  programs.fish.enable = true;
}
