{ pkgs, ... }:

# ============================================================
# Haskell development shell
# ============================================================
# Pins a specific GHC version and the MATCHING HLS build.
# This solves the version-matching problem described in modules/dev/haskell.nix.
#
# nixpkgs ships HLS pre-built for each GHC it supports. We select
# a GHC version by using `pkgs.haskell.packages.ghcXYZ` where XYZ is
# the GHC major.minor version with dots removed (e.g. ghc966 = GHC 9.6.6).
#
# To list available GHC versions in your nixpkgs revision:
#   nix repl '<nixpkgs>'
#   :a pkgs.haskell.packages
#   # tab-complete to see all ghcXYZ attrs
# ============================================================
let
  # Pin to a specific GHC. Change this to switch versions project-wide.
  # GHC 9.6.x is the current stable LTS target.
  ghcVersion = "ghc967";
  hpkgs = pkgs.haskell.packages.${ghcVersion};
in
pkgs.mkShell {
  name = "haskell-dev";

  packages = [
    # ---- Compiler and build tools ----
    hpkgs.ghc # GHC compiler — THIS version, matching HLS below
    pkgs.cabal-install # Cabal build tool (version-agnostic, from top-level pkgs)
    pkgs.stack # Stack build tool (optional, manages its own GHC)

    # ---- Language Server (same hpkgs = guaranteed version match) ----
    # haskell-language-server is wrapped by nixpkgs to use THIS GHC.
    hpkgs.haskell-language-server

    # ---- Formatters and linters ----
    hpkgs.fourmolu # must match GHC for correctness on newer syntax
    pkgs.hlint # static analysis (ships as standalone binary, flexible)
    pkgs.stylish-haskell

    # ---- REPL and interactive development ----
    hpkgs.ghcid # file watcher + GHCi reload
    hpkgs.hoogle # Haskell documentation search (matching this GHC)

    # ---- Build system support ----
    pkgs.pkg-config # used by Haskell bindings to C libraries
    pkgs.zlib # many packages need this
    pkgs.openssl # for tls/crypto packages
  ];

  shellHook = ''
    echo "Haskell dev shell"
    echo "  GHC:  $(ghc --version)"
    echo "  Cabal: $(cabal --version | head -1)"
    echo "  HLS:  $(haskell-language-server-wrapper --version 2>/dev/null || echo 'not found')"
    echo ""
    echo "  Tip: run 'cabal update' to sync the Hackage package index"
  '';
}
