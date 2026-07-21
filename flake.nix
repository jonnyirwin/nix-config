{
  # ============================================================
  # Jonny's Home Manager Flake
  # ============================================================
  #
  # This is the root entry point for the entire Nix configuration.
  # It wires together all inputs (external Nix repositories) and
  # exposes two types of outputs:
  #
  #   1. homeConfigurations — the Home Manager setup that manages
  #      packages, dotfile symlinks, and shell config for the
  #      "jonny" user on the "debian" host.
  #
  #   2. devShells — per-stack development environments you enter
  #      with `nix develop .#haskell` (or elixir/rust/ruby).
  #      Each shell puts the runtime + LSP + formatter for that
  #      stack on PATH without polluting your global environment.
  #
  # ============================================================
  # IMPORTANT: this is a STANDALONE Home Manager setup (not NixOS).
  # You are running Debian; Nix is installed as a package manager
  # alongside the Debian system packages. Home Manager manages your
  # *user* environment (~/.config/, ~/bin/, shell init, etc.) but
  # does NOT manage system services, display managers, or the kernel.
  # ============================================================
  #
  # First-time setup:
  #   1. Install Nix:  https://nixos.org/download (multi-user)
  #   2. Enable flakes:  already done in ~/.dotfiles/nix/.config/nix/nix.conf
  #   3. Install Home Manager standalone:
  #        nix run home-manager -- init --switch
  #      (or just: nix run home-manager -- switch --flake .#jonny@debian)
  #   4. After the first switch, subsequent updates are:
  #        home-manager switch --flake .#jonny@debian
  #      Or add the alias defined in modules/shell.nix: `hms`
  # ============================================================

  description = "Jonny's Home Manager configuration";

  inputs = {
    # ---- Core ----

    # nixpkgs-unstable gives us the latest package versions.
    # Trade-off: very rarely a package temporarily breaks on unstable.
    # Your old nix-config used nixos-24.11 (stable) + a separate pkgs-unstable
    # overlay for specific packages. We use unstable as the base here because
    # most of your tooling (neovim, LSPs, etc.) benefits from being current.
    # To revert to stable: change to "github:nixos/nixpkgs/nixos-24.11"
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      # `follows` means home-manager uses the same nixpkgs revision as us,
      # preventing two different versions of nixpkgs being downloaded.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ---- Rust toolchains ----
    # fenix provides every Rust toolchain component (stable/beta/nightly)
    # from the official Rust release archive, as proper nix derivations.
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ---- NixOS hardware profiles ----
    # Community-maintained hardware modules for specific devices
    # (Framework, ThinkPad, Raspberry Pi, etc.). Optional — only needed
    # if your machine has a profile in the repo.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # ---- Theming ----
    # nix-colors provides base16 colour schemes as nix attributes.
    # It lets you reference colours like `config.colorScheme.palette.base0D`
    # in any module — write a colour once, use it in waybar, starship, kitty, etc.
    # Your old nix-config already used this with catppuccin-mocha.
    nix-colors.url = "github:misterio77/nix-colors";

    # catppuccin/nix provides pre-built Catppuccin theme modules for many
    # programs (kitty, bat, delta, starship, fish, btop, etc.). Rather than
    # hand-crafting Catppuccin colour values, you enable the module and it
    # handles the theme file generation.
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, home-manager, fenix, nix-colors, catppuccin, nixos-hardware, ... }@inputs:
    let
      # The only system architecture we care about right now.
      # Change to "aarch64-linux" for ARM (e.g. Raspberry Pi / Apple Silicon VM).
      system = "x86_64-linux";

      # Standard nixpkgs package set, with unfree packages allowed.
      # Unfree is needed for things like certain fonts or proprietary tools.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # A separate pkgs with the fenix overlay merged in, giving us
      # `pkgs.fenix.*` for Rust toolchain components (used in devShells).
      pkgsWithFenix = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ fenix.overlays.default ];
      };

    in {

      # ----------------------------------------------------------
      # Home Manager configuration
      # ----------------------------------------------------------
      # The attribute name "jonny@debian" is just a label — it has
      # no technical meaning, but using "user@host" is conventional
      # and makes it obvious what machine this config targets.
      # If you add a second machine (e.g. a laptop), you'd add:
      #   homeConfigurations."jonny@laptop" = ...
      # ----------------------------------------------------------
      homeConfigurations."jonny@debian" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # extraSpecialArgs lets us pass arbitrary values into every
        # module as function arguments, alongside the standard ones
        # (pkgs, lib, config, osConfig).
        extraSpecialArgs = {
          # Pass fenix through so the Rust module can use its overlays.
          inherit fenix;
          # nix-colors must be explicitly passed so home.nix can reference
          # nix-colors.colorSchemes.* — the HM module alone doesn't inject it.
          inherit nix-colors;
          # Pass the full inputs set so overlays.nix and other modules can
          # reference inputs.fenix.overlays.default etc.
          inherit inputs;
        };

        modules = [
          # nix-colors: adds the `config.colorScheme` option used in home.nix.
          nix-colors.homeManagerModules.default

          # catppuccin/nix: adds `programs.<name>.catppuccin.enable` options
          # and the global `catppuccin.flavor` / `catppuccin.accent` options.
          catppuccin.homeModules.catppuccin

          # Shared base config (identity, universal tools, shell, editor).
          ./home.nix

          # Machine-specific config (desktop, dev stacks, hardware settings).
          # Change this to ./hosts/work-laptop.nix for a different machine.
          ./hosts/debian.nix
        ];
      };

      # ----------------------------------------------------------
      # Adding a second machine
      # ----------------------------------------------------------
      # Copy this block and change the label + host file:
      #
      # homeConfigurations."jonny@work-laptop" = home-manager.lib.homeManagerConfiguration {
      #   inherit pkgs;
      #   extraSpecialArgs = { inherit fenix nix-colors inputs; };
      #   modules = [
      #     nix-colors.homeManagerModules.default
      #     catppuccin.homeManagerModules.catppuccin
      #     ./home.nix
      #     ./hosts/work-laptop.nix   # create this file
      #   ];
      # };
      #
      # Then switch on that machine:
      #   home-manager switch --flake ~/git/nix#jonny@work-laptop
      # ----------------------------------------------------------

      # ----------------------------------------------------------
      # NixOS configurations
      # ----------------------------------------------------------
      # Each entry here is a full NixOS system for one machine.
      # Home Manager is wired in as a NixOS module so a single
      # `nixos-rebuild switch` handles both system and user config.
      #
      # To add a new machine:
      #   1. Copy hosts/template/ to hosts/<hostname>/
      #   2. Set networking.hostName in hosts/<hostname>/default.nix
      #   3. Generate hardware config on the machine:
      #        nixos-generate-config --show-hardware-config > hardware.nix
      #   4. Add a nixosConfigurations entry below (copy the block)
      #   5. Deploy: nixos-rebuild switch --flake ~/git/nix#<hostname>
      #
      # nixos-hardware profiles: https://github.com/NixOS/nixos-hardware
      # Uncomment the relevant module inside hosts/<hostname>/default.nix
      # e.g. nixos-hardware.nixosModules.framework-13-7040-amd
      # ----------------------------------------------------------

      nixosConfigurations."mac" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          # Shared NixOS config (locale, users, networking, SSH, base packages).
          ./nixos-modules/common.nix
          # Desktop environment (Sway, display manager, fonts, portals).
          ./nixos-modules/desktop.nix

          # Machine-specific system config + hardware config.
          # laptop.nix is imported inside hosts/mac/default.nix.
          ./hosts/mac/default.nix

          # Home Manager wired in as a NixOS module.
          # A single `nixos-rebuild switch` handles both system and user config.
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs    = true;
            home-manager.useUserPackages  = true;
            home-manager.extraSpecialArgs = { inherit fenix nix-colors inputs; };
            home-manager.users.jonny.imports = [
              nix-colors.homeManagerModules.default
              catppuccin.homeModules.catppuccin
              ./home.nix
              ./hosts/mac/home.nix
            ];
          }
        ];
      };

      # ---- optiplex: Dell OptiPlex desktop (Sway) ----
      nixosConfigurations."optiplex" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos-modules/common.nix
          ./nixos-modules/desktop.nix
          ./hosts/optiplex/default.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs    = true;
            home-manager.useUserPackages  = true;
            home-manager.extraSpecialArgs = { inherit fenix nix-colors inputs; };
            home-manager.users.jonny.imports = [
              nix-colors.homeManagerModules.default
              catppuccin.homeModules.catppuccin
              ./home.nix
              ./hosts/optiplex/home.nix
            ];
          }
        ];
      };

      # Template for adding further machines — copy and adjust:
      # nixosConfigurations."myhostname" = nixpkgs.lib.nixosSystem {
      #   inherit system;
      #   specialArgs = { inherit inputs; };
      #   modules = [
      #     ./nixos-modules/common.nix
      #     ./nixos-modules/desktop.nix
      #     ./hosts/myhostname/default.nix
      #     home-manager.nixosModules.home-manager
      #     {
      #       home-manager.useGlobalPkgs    = true;
      #       home-manager.useUserPackages  = true;
      #       home-manager.extraSpecialArgs = { inherit fenix nix-colors inputs; };
      #       home-manager.users.jonny.imports = [
      #         nix-colors.homeManagerModules.default
      #         catppuccin.homeManagerModules.catppuccin
      #         ./home.nix
      #         ./hosts/myhostname/home.nix
      #       ];
      #     }
      #   ];
      # };

      # ----------------------------------------------------------
      # Development shells
      # ----------------------------------------------------------
      # These are hermetic shell environments for each tech stack.
      # Usage:
      #   nix develop .#haskell     — one-off
      #   echo "use flake .#rust" > .envrc && direnv allow   — per-project
      #
      # The shells are defined in devShells.nix and imported here.
      # ----------------------------------------------------------
      devShells.${system} = import ./devShells.nix { inherit pkgs pkgsWithFenix; };

      # A convenient formatter for this flake's .nix files.
      # Run: nix fmt
      formatter.${system} = pkgs.alejandra;
    };
}
