{
  description = "Jonny Irwin's NixOS and Home Manager Configuration";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";	
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, nixvim, ... }:
  let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    #pkgs = import nixpkgs {
      #inherit system;
      #config.allowUnfree = true;
    #};
  in
  {
    nixosConfigurations = {
      nixos = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/hosts/nixos/configuration.nix
        ];
      };
      bearnagh = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/hosts/bearnagh/configuration.nix
        ];
      };
    };
    homeConfigurations = {
      "jonny@nixos" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ 
          nixvim.homeManagerModules.nixvim
          ./home-manager/home.nix
        ];
      };
      "jonny@bearnagh" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ 
          nixvim.homeManagerModules.nixvim
          ./home-manager/home.nix
        ];
      };
    };
  };
}
