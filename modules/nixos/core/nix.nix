{ pkgs, ... }:

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

  # nvd prints a package-level diff of what a switch changes. Not wired into
  # activation — run it deliberately against a build:
  #   nixos-rebuild build --flake .#optiplex && nvd diff /run/current-system ./result
  environment.systemPackages = [ pkgs.nvd ];
}
