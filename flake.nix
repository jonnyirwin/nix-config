{
  description = "Jonny's NixOS + Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rust toolchains as proper derivations (stable/beta/nightly), used by devShells.
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Per-device hardware profiles. Selected per host via jonny.hardware.profiles
    # — see modules/nixos/hardware/default.nix.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Pre-built Catppuccin theme modules for programs that have one.
    # Raw palette values come from lib/schemes/ instead.
    catppuccin.url = "github:catppuccin/nix";

    # Secrets encrypted in-repo, decrypted at activation. See .sops.yaml.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative partitioning. A host's disk layout is code, so provisioning a
    # replacement machine does not involve a manual cryptsetup session.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware detection: `nixos-facter -o hosts/<name>/facter.json` writes a
    # machine report, and this module turns it into the kernel modules and
    # firmware that machine needs. Replaces the guesswork half of
    # nixos-generate-config; disko replaces the disk half.
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";

    # Own project: terminal RSS reader. Installed from its own flake rather than
    # packaged here, so the package definition stays with the source.
    # `nix flake update rss-is-terminal` picks up new commits.
    rss-is-terminal = {
      url = "github:jonnyirwin/rss_is_terminal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, fenix, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      # Architectures this flake can produce per-system outputs for. Hosts do
      # not consult this list — their platform comes from their own
      # hardware.nix — so adding a machine never means editing it.
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: lib.genAttrs systems (system: f (pkgsFor system));

      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ fenix.overlays.default ];
      };

      # Every directory under hosts/ becomes a nixosConfiguration. Adding a
      # machine means adding a directory — nothing here changes.
      hostNames = lib.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );

      mkHost = import ./lib/mkHost.nix { inherit inputs; };
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      # Consumable from another flake — useful for a machine that should take
      # some of this config without inheriting the whole thing.
      nixosModules.default = ./modules/nixos;
      homeModules.default = ./modules/home;

      # Per-stack dev environments, replacing mise/ghcup:
      #   nix develop ~/git/nix#ruby
      #   echo "use flake ~/git/nix#ruby" > .envrc && direnv allow
      devShells = forAllSystems (pkgs: import ./devshells { inherit pkgs; });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);

      # `nix flake check` evaluates every host and lints the tree, so a dead
      # binding or an anti-pattern fails rather than lingering.
      checks = forAllSystems (pkgs: {
        statix = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
          # hosts/*/hardware.nix is generated; not ours to restyle.
          statix check --ignore hardware.nix ${self} && touch $out
        '';

        deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
          # Same reasoning: its unused module arguments are not ours to fix.
          deadnix --fail --exclude ${self}/hosts/*/hardware.nix ${self} && touch $out
        '';
      });
    };
}
