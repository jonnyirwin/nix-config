{ config, pkgs, lib, nix-colors, ... }:

# ============================================================
# Top-level Home Manager configuration — shared across all hosts
# ============================================================
#
# This file contains UNIVERSAL config — identical on every machine.
# Machine-specific config (desktop environment, per-host dev stacks,
# hardware settings) lives in hosts/<hostname>.nix, which is loaded
# alongside this file in flake.nix's `modules = [...]` list.
#
# Module evaluation: HM processes all imported modules simultaneously
# and deep-merges their attribute sets. Order of imports doesn't matter
# for correctness, but comments here document the intent of each group.
# ============================================================

{
  # ----------------------------------------------------------
  # Identity
  # ----------------------------------------------------------
  home.username    = "jonny";
  home.homeDirectory = "/home/jonny";

  # HM state version: controls backwards-compatibility shims in HM itself.
  # Set once; don't change unless HM tells you to during an upgrade.
  home.stateVersion = "24.11";

  # ----------------------------------------------------------
  # XDG base directories
  # ----------------------------------------------------------
  # Makes HM write to ~/.config/, ~/.local/share/, ~/.cache/
  # instead of the home root.
  xdg.enable = true;

  # ----------------------------------------------------------
  # Colour scheme (nix-colors)
  # ----------------------------------------------------------
  # Sets config.colorScheme to the Catppuccin Mocha base16 palette.
  # Reference in any module: config.colorScheme.palette.base0D → "#89b4fa"
  # Use this when a program needs raw hex values in a custom config.
  # (catppuccin/nix module handles its own theme files separately.)
  colorScheme = nix-colors.colorSchemes.catppuccin-mocha;

  # ----------------------------------------------------------
  # Global Catppuccin theme (catppuccin/nix)
  # ----------------------------------------------------------
  # Sets the default flavour and accent for ALL programs that use
  # `programs.<name>.catppuccin.enable = true`. Individual programs
  # can override these if needed (e.g. catppuccin.flavor = "latte").
  catppuccin.flavor = "mocha";
  catppuccin.accent = "mauve";

  # nixpkgs.config.allowUnfree is set in flake.nix (system level).
  # It cannot be set here when home-manager.useGlobalPkgs = true.

  # ----------------------------------------------------------
  # Shell-agnostic aliases
  # ----------------------------------------------------------
  # home.shellAliases is propagated to every shell HM manages
  # (fish, bash, zsh, etc.) — more portable than programs.fish.shellAliases.
  # If you add bash or zsh later, these aliases appear automatically.
  home.shellAliases = {
    # Modern CLI replacements (binaries from packages.nix / programs.nix)
    ls   = "eza --icons";
    ll   = "eza -la --icons --git";
    lt   = "eza --tree --level=2 --icons";
    cat  = "bat --style=plain";
    grep = "rg";
    find = "fd";
    top  = "btop";    # switched from bottom (btm) to btop

    # Home Manager convenience
    hms  = "home-manager switch --flake ${config.home.homeDirectory}/git/nix#jonny@debian";
    hmn  = "home-manager news   --flake ${config.home.homeDirectory}/git/nix#jonny@debian";

    # Nix convenience — run/enter any nixpkgs package without installing
    nxs  = "nix shell nixpkgs#";   # `nxs curl` → shell with curl on PATH
    nxr  = "nix run   nixpkgs#";   # `nxr cowsay hello` → run without installing

    # Your Rails aliases from config.fish (kept here so they're shell-agnostic)
    killrails  = "pkill -f rails; pkill -f puma; rm -f tmp/pids/server.pid";
    railsdebug = "env RUBY_DEBUG_OPEN=true RUBY_DEBUG_PORT=38698 bundle exec rails s";
  };

  # ----------------------------------------------------------
  # Universal module imports (every machine gets these)
  # ----------------------------------------------------------
  imports = [
    ./modules/overlays.nix    # Overlay tutorial + nixpkgs patches
    ./modules/git.nix         # Git, delta, gh CLI
    ./modules/packages.nix    # Core CLI tools
    ./modules/programs.nix    # bat, lazygit, zathura, btop (with catppuccin)
    ./modules/shell.nix       # Fish, Starship, zoxide, atuin, fzf, direnv
    ./modules/editor.nix      # Neovim + LSP tools on PATH
    ./modules/terminal.nix    # Kitty + Tmux
    ./modules/ssh.nix         # SSH client config
    ./modules/services.nix    # gpg-agent, syncthing, background services
    ./modules/activation.nix  # home.activation one-time/periodic setup scripts
  ];
  # NOTE: desktop.nix and dev/*.nix are imported in hosts/debian.nix,
  # not here, so headless machines don't pull in GUI and language tooling.

  # ----------------------------------------------------------
  # Let Home Manager manage itself
  # ----------------------------------------------------------
  programs.home-manager.enable = true;
}
