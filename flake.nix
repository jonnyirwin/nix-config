{
  description = "Jonny Irwin's NixOS and Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
		nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nixvim,
    nixpkgs-unstable,
		nix-colors,
    ...
  }: let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
        "electron-27.3.11"
      ];
    };
  in {
    nixosConfigurations = {
      nixos = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pkgs-unstable;
        };
        modules = [
          ./nixos/hosts/nixos/configuration.nix
        ];
      };
      bearnagh = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pkgs-unstable;
        };
        modules = [
          ./nixos/hosts/bearnagh/configuration.nix
        ];
      };
    };
    homeConfigurations = {
      "jonny@bearnagh" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit pkgs-unstable;
					inherit nix-colors;
        };
        modules = [
          nixvim.homeManagerModules.nixvim
					nix-colors.homeManagerModules.default
          ./home-manager/home.nix
        ];
      };
    };
  };
}
