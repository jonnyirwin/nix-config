{ inputs }:

# Builds one nixosConfiguration from a directory under hosts/.
#
# A host directory contains:
#   default.nix   required — toggles, machine facts, and nixpkgs.hostPlatform
#   facter.json   required — hardware report, see hosts/optiplex/default.nix
#   disks/        required — disko layout, which also derives fileSystems
#   home.nix      optional — per-host Home Manager overrides
#
# `system` is deliberately not passed to nixosSystem: the host's own default.nix
# sets nixpkgs.hostPlatform, so the architecture comes from the machine rather
# than from a list here. That is what lets an aarch64 host join without any
# change here or in flake.nix.

name:

let
  inherit (inputs) nixpkgs home-manager catppuccin;

  hostDir = ../hosts + "/${name}";
  homeFile = hostDir + "/home.nix";
in
nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };

  modules = [
    ../modules/nixos
    hostDir

    # NixOS-side catppuccin.* options — needed here (not just inside the
    # home-manager block below) because SDDM is a system service, themed
    # before any Home Manager profile is activated. See
    # modules/nixos/desktop/sddm.nix.
    catppuccin.nixosModules.catppuccin

    home-manager.nixosModules.home-manager
    {
      networking.hostName = nixpkgs.lib.mkDefault name;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };

        # Back up rather than fail when an unmanaged file is in the way. Without
        # this, activation aborts on the first collision and leaves the switch
        # half-applied — which is exactly what happened migrating off ~/.dotfiles.
        backupFileExtension = "hm-backup";

        users.jonny.imports = [
          catppuccin.homeModules.catppuccin
          ../modules/home
        ] ++ nixpkgs.lib.optional (builtins.pathExists homeFile) homeFile;
      };
    }
  ];
}
