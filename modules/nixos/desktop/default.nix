{ lib, ... }:

{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./fonts.nix
    ./graphics.nix
    ./greetd.nix
    ./onepassword.nix
    ./portals.nix
    ./sway.nix
  ];

  options.jonny.desktop.enable =
    lib.mkEnableOption "the graphical desktop (Sway session, audio, portals, GPU)";
}
