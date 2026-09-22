{ pkgs, ... }:

# ============================================================
# Haskell development shell
# ============================================================
# Provides a GHC and the MATCHING HLS build.
#
# nixpkgs ships HLS pre-built for each GHC it supports, so taking both from
# one `pkgs.haskell.packages.ghcXYZ` set guarantees the pair agrees. The
# version itself lives in lib/default.nix, shared with the Neovim fallback
# and the global ghci — change it there, not here.
# ============================================================
let
  hpkgs = (import ../lib { inherit (pkgs) lib; }).haskellPackages pkgs;
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
