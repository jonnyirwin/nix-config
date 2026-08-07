{ pkgs, inputs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Keep a fortnight of generations rather than growing the store forever.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  # `useGlobalPkgs = true` (see lib/mkHost.nix) means home-manager's `pkgs`
  # is this exact one, so this overlay reaches modules/home/desktop/aseprite.nix
  # too. See the nixpkgs-aseprite input in flake.nix for why aseprite is
  # pinned separately instead of coming from the main nixpkgs.
  nixpkgs.overlays = [
    (final: prev: {
      aseprite = (import inputs.nixpkgs-aseprite {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }).aseprite;
    })
  ];

  # nvd prints a package-level diff of what a switch changes. Not wired into
  # activation — run it deliberately against a build:
  #   nixos-rebuild build --flake .#optiplex && nvd diff /run/current-system ./result
  environment.systemPackages = [ pkgs.nvd ];
}
