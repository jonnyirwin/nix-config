{
  description = "Jonny Irwin system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
    home-manager = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      nixos = lib.nixosSystem {
        inherit system;
	modules = [
          ./nixos/configuration.nix
	];
      };
    };
  };
}
