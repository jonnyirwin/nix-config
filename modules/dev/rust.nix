{ config, pkgs, fenix, ... }:

# ============================================================
# Rust global tooling
# ============================================================
#
# Rust toolchain options in Nix
# ──────────────────────────────
# There are three approaches to managing Rust with Nix:
#
#   1. pkgs.rust (stable channel from nixpkgs):
#      Simple. `pkgs.rustc`, `pkgs.cargo`, `pkgs.rust-analyzer`.
#      Fixed at whatever version nixpkgs-unstable ships.
#      Drawback: no easy way to switch to nightly for a specific project.
#
#   2. rustup (the official Rust installer):
#      Install rustup via nix, let it manage toolchains.
#      Familiar if you know Rust. Keeps toolchains in ~/.rustup/.
#      Drawback: partially defeats nix reproducibility; rustup
#      fetches things from the internet at runtime.
#
#   3. fenix (nix-community/fenix):
#      Provides nix packages for every Rust toolchain component
#      (stable, beta, nightly, specific dates) from the official
#      Rust release archive. Used here.
#      Pros: fully nix-managed, reproducible, component granularity.
#      Cons: fenix is an extra flake input, slightly more setup.
#
# This module uses fenix for the global toolchain (stable) and
# shows how to use fenix in devShells for per-project nightly.
# ============================================================
#
# Overlays explained (important concept!)
# ───────────────────────────────────────
# An OVERLAY is a function that takes (final: prev:) and returns an
# attrset of packages. Nix applies overlays to the package set,
# letting you:
#   a) Add new packages not in nixpkgs
#   b) Override existing packages (e.g. change build flags)
#   c) Add attributes derived from other packages in the set
#
# fenix provides an overlay that adds `pkgs.fenix.*` to your package
# set. In flake.nix we create `pkgsWithFenix` like this:
#
#   pkgsWithFenix = import nixpkgs {
#     overlays = [ fenix.overlays.default ];
#   };
#
# The overlay function signature is:
#   final: prev:
#   { fenix = ...; }
#
#   - `prev` is the package set BEFORE the overlay (vanilla nixpkgs)
#   - `final` is the package set AFTER all overlays are applied
#     (useful if your overlay's packages depend on other overlays)
#
# More overlay examples:
#
#   # Add a package not in nixpkgs:
#   final: prev: {
#     my-tool = prev.callPackage ./pkgs/my-tool.nix {};
#   }
#
#   # Override a package's version:
#   final: prev: {
#     neovim = prev.neovim.overrideAttrs (old: {
#       version = "0.10.0";
#       src = prev.fetchFromGitHub { ... };
#     });
#   }
#
#   # Build a package with different flags:
#   final: prev: {
#     kitty = prev.kitty.override { openssl = final.openssl_3; };
#   }
#
# Overlays are passed to `import nixpkgs { overlays = [...]; }` in
# flake.nix (see the pkgsWithFenix definition there).
# ============================================================

{
  home.packages =
    let
      # `fenix` is passed as a specialArg from flake.nix (NOT pkgs.fenix).
      # It is the raw fenix flake output, not an overlay-modified pkgs set.
      # We access its packages via: fenix.packages.${pkgs.system}.*
      #
      # The difference from pkgs.fenix:
      #   - pkgs.fenix requires the fenix overlay applied to that pkgs instance
      #   - fenix.packages.${system} accesses fenix directly from the flake input
      # Both work; using the flake input directly avoids needing pkgsWithFenix
      # in HM modules (which use the standard `pkgs` from homeManagerConfiguration).
      fenixPkgs = fenix.packages.${pkgs.system};

      rustToolchain = fenixPkgs.stable.withComponents [
        "rustc"          # the compiler
        "cargo"          # package manager + build tool
        "rust-std"       # standard library
        "rustfmt"        # code formatter (cargo fmt)
        "clippy"         # linter (cargo clippy)
        "rust-src"       # source code of std — needed by rust-analyzer
        "rust-docs"      # offline documentation
      ];

      # rust-analyzer from fenix is always compiled to match the selected
      # toolchain, avoiding the "incompatible rustc" warning.
      rustAnalyzer = fenixPkgs.stable.rust-analyzer;

    in [
      # ---- Core toolchain ----
      rustToolchain    # rustc, cargo, rustfmt, clippy (all in one derivation)
      rustAnalyzer     # LSP server — add to your lsp.lua:
                       # vim.lsp.config('rust_analyzer', { capabilities = capabilities })
                       # vim.lsp.enable('rust_analyzer')

      # ---- Build dependencies ----
      # Many Rust crates link against C libraries. These are commonly needed:
      pkgs.pkg-config  # required by crates that use pkg-config to find system libs
      pkgs.openssl     # ring, reqwest, and many others need this
      pkgs.libiconv    # string conversion (needed on macOS; harmless on Linux)

      # ---- Common dev tools ----
      pkgs.cargo-watch     # `cargo watch -x run` — reruns on file change
      pkgs.cargo-edit      # `cargo add/remove/upgrade` — manage dependencies
      pkgs.cargo-expand    # `cargo expand` — shows macro expansions
      pkgs.cargo-nextest   # faster test runner replacing `cargo test`
      pkgs.cargo-audit     # checks for known vulnerabilities in deps
      pkgs.cargo-flamegraph # profiling via flamegraph.svg
    ];

  # rust-analyzer needs RUST_SRC_PATH to resolve std types in completions.
  home.sessionVariables = {
    RUST_SRC_PATH = "${fenix.packages.${pkgs.system}.stable.rust-src}/lib/rustlib/src/rust/library";
  };

  # ----------------------------------------------------------
  # Per-project toolchain pinning
  # ----------------------------------------------------------
  # For projects that need a specific Rust version or nightly features,
  # use a rust-toolchain.toml in the project root:
  #
  #   [toolchain]
  #   channel = "nightly-2024-11-01"
  #   components = ["rustc", "cargo", "rustfmt", "clippy", "rust-src"]
  #
  # Then in the project's .envrc:
  #   use flake /home/jonny/git/nix#rust
  #
  # The rust devShell in devShells.nix respects rust-toolchain.toml via
  # fenix.fromToolchainFile, giving you the exact toolchain the project
  # needs without polluting your global environment.
  # ----------------------------------------------------------
}
