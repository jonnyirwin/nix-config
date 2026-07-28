{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  # Steam has to be system-level: the module adds the udev rules for
  # controllers, the 32-bit loader environment the client itself is built
  # against, and the FHS wrapper Proton needs. Installing the package into a
  # Home Manager profile gets you none of that.
  #
  # The 32-bit GL/Vulkan drivers Steam needs come from
  # hardware.graphics.enable32Bit in ./graphics.nix, which is already on for
  # every desktop host. Steam's own UI is X11, so it runs on sway's XWayland.
  options.jonny.desktop.steam.enable =
    lib.mkEnableOption "Steam (system-level: 32-bit runtime, Proton, controller udev rules)";

  config = lib.mkIf (cfg.enable && cfg.steam.enable) {
    programs.steam = {
      enable = true;

      # Both open ports in the firewall, which is on by default, so they're
      # opt-in rather than free:
      #   remotePlay              — streaming a game to another device
      #   localNetworkGameTransfers — pulling an already-downloaded game off
      #                               another Steam machine on the LAN instead
      #                               of re-downloading it
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    # Lets a game ask for the performance CPU governor and higher I/O priority
    # while it runs, and drop back afterwards. Proton knows how to use it, and
    # Steam launch options can with `gamemoderun %command%`.
    programs.gamemode.enable = true;
  };
}
