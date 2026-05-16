{ config, pkgs, lib, ... }:

# ============================================================
# Haskell global tooling
# ============================================================
#
# The GHC / HLS version-pairing problem
# ─────────────────────────────────────
# Haskell Language Server (HLS) and GHC must be compiled against the
# SAME GHC version, otherwise HLS refuses to start with an error like:
#
#   "ghc version mismatch: binary was built with X, trying to use Y"
#
# This creates a dilemma for Nix:
#
#   Option A — Nix manages GHC + HLS:
#     nixpkgs ships a matrix of HLS builds, one per GHC version.
#     You'd write:
#       pkgs.haskell.packages.ghc966.haskell-language-server
#     This works but pins you to nixpkgs' GHC selection. Switching
#     GHC versions means changing the nix config and rebuilding.
#
#   Option B — ghcup manages GHC + HLS (your current approach):
#     ghcup installs any GHC/HLS version independently and keeps them
#     matched. Your neovim config already appends ~/.ghcup/bin to PATH.
#     Downside: not reproducible across machines without also running
#     ghcup on each one.
#
#   Option C — Nix devShells pin GHC + HLS together (RECOMMENDED):
#     Each project's devShell (see devShells.nix) declares the exact
#     GHC version it needs, and nixpkgs provides the matching HLS.
#     Your global environment uses ghcup; project environments use nix.
#     This is the best of both: flexibility globally, reproducibility
#     per project.
#
# This module takes Option B for the global home environment and
# installs only tools that are version-agnostic (they work with any
# GHC on PATH). The per-project pinning happens in devShells.nix.
# ============================================================

{
  home.packages = with pkgs; [

    # ---- Build tooling ----
    # cabal-install is the Cabal build tool. Like `stack` but without
    # the curated snapshot approach. Works with any GHC on PATH.
    # Note: your mise.toml mentions ghcup but not cabal — ghcup can
    # install cabal for you: `ghcup install cabal latest`
    # Providing it here too ensures it's always available.
    cabal-install

    # stack is an alternative build tool with curated LTS snapshots.
    # It manages its own GHC versions per project — useful for projects
    # that use stack.yaml instead of cabal.project.
    # Uncomment if you work with stack-based projects:
    # stack

    # ---- Code quality tools (version-agnostic binaries) ----
    # hlint analyses Haskell source for style suggestions and common mistakes.
    # It ships as a standalone binary and works with source files directly,
    # independent of which GHC compiled your project.
    hlint

    # fourmolu is the formatter your neovim config sets as formattingProvider.
    # Like ormolu but with a few extra configuration options (via fourmolu.yaml).
    # Your lsp.lua sets `haskell.formattingProvider = "fourmolu"`.
    fourmolu

    # ormolu is the "official" formatter if you want zero config.
    # Uncomment to switch; remember to change formattingProvider in haskell.lua.
    # ormolu

    # stylish-haskell formats import blocks and pragmas (doesn't format expressions).
    # Often used alongside hlint.
    stylish-haskell

    # ---- Hoogle (local documentation search) ----
    # hoogle lets you search Haskell functions by type signature.
    # Your neovim haskell.lua uses `ht.hoogle.hoogle_signature` which
    # queries hoogle. With a local database it works offline.
    #
    # Build the database once: hoogle generate --local
    haskellPackages.hoogle

    # ---- GHCi helpers ----
    # ghcid watches your project and reruns GHCi on every save.
    # Faster feedback loop than `cabal build` for development.
    ghcid
  ];

  # ============================================================
  # IMPORTANT: GHC and HLS are NOT installed here.
  # ============================================================
  # Install them via ghcup (already in your PATH via ~/.ghcup/bin):
  #
  #   ghcup install ghc   recommended    # latest stable GHC
  #   ghcup install hls   recommended    # matching HLS
  #   ghcup set ghc recommended          # make it the default
  #
  # Or use the devShells in devShells.nix for per-project hermetic envs:
  #   cd my-haskell-project
  #   echo "use flake /home/jonny/git/nix#haskell" > .envrc
  #   direnv allow
  # ============================================================
}
