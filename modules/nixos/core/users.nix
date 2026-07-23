{ pkgs, ... }:

{
  users.users.jonny = {
    isNormalUser = true;
    description = "Jonny Irwin";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.fish;
  };

  # Fish must be enabled system-wide so /etc/shells lists it — otherwise it is
  # not a valid login shell, whatever users.users.jonny.shell says.
  programs.fish.enable = true;
}
