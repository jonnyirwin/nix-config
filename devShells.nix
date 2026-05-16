{ pkgs, pkgsWithFenix }:

# ============================================================
# Development shells — hermetic per-stack environments
# ============================================================
#
# A devShell is a Nix-managed shell environment that adds specific
# tools to PATH for the duration of the shell session, without
# polluting your global home environment.
#
# How to use:
#
#   One-off interactive:
#     nix develop /home/jonny/git/nix#haskell
#     nix develop /home/jonny/git/nix#elixir
#     nix develop /home/jonny/git/nix#rust
#     nix develop /home/jonny/git/nix#ruby
#
#   Per-project via direnv (RECOMMENDED):
#     echo "use flake /home/jonny/git/nix#haskell" > .envrc
#     direnv allow
#     # Now every `cd` into this directory activates the Haskell env.
#
#   If a project has its OWN flake.nix with a devShell:
#     echo "use flake" > .envrc
#     direnv allow
#     # Uses the project's own shell definition.
#
# How devShells work:
#
#   `pkgs.mkShell` creates a derivation that, when entered, sets:
#     - PATH to include all packages in `packages`
#     - Any variables set in `shellHook`
#     - Linker flags for libraries in `buildInputs` / `nativeBuildInputs`
#
#   The difference between `packages`, `buildInputs`, and `nativeBuildInputs`:
#     - packages         → things you want on PATH (binaries)
#     - buildInputs      → C libraries needed at link time (headers + .so files)
#     - nativeBuildInputs → build tools that produce output for the HOST
#                           (compilers, code generators; important for cross-compilation)
#   For simple dev shells, putting everything in `packages` is fine.
#
# ============================================================

{
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
  haskell =
    let
      # Pin to a specific GHC. Change this to switch versions project-wide.
      # GHC 9.6.x is the current stable LTS target (2024-2025).
      ghcVersion = "ghc966";
      hpkgs = pkgs.haskell.packages.${ghcVersion};
    in
    pkgs.mkShell {
      name = "haskell-dev";

      packages = [
        # ---- Compiler and build tools ----
        hpkgs.ghc           # GHC compiler — THIS version, matching HLS below
        pkgs.cabal-install  # Cabal build tool (version-agnostic, from top-level pkgs)
        pkgs.stack          # Stack build tool (optional, manages its own GHC)

        # ---- Language Server (same hpkgs = guaranteed version match) ----
        # haskell-language-server is wrapped by nixpkgs to use THIS GHC.
        hpkgs.haskell-language-server

        # ---- Formatters and linters ----
        hpkgs.fourmolu      # must match GHC for correctness on newer syntax
        pkgs.hlint          # static analysis (ships as standalone binary, flexible)
        pkgs.stylish-haskell

        # ---- REPL and interactive development ----
        hpkgs.ghcid         # file watcher + GHCi reload
        pkgs.hoogle         # Haskell documentation search

        # ---- Build system support ----
        pkgs.pkg-config     # used by Haskell bindings to C libraries
        pkgs.zlib           # many packages need this
        pkgs.openssl        # for tls/crypto packages
      ];

      shellHook = ''
        echo "Haskell dev shell"
        echo "  GHC:  $(ghc --version)"
        echo "  Cabal: $(cabal --version | head -1)"
        echo "  HLS:  $(haskell-language-server-wrapper --version 2>/dev/null || echo 'not found')"
        echo ""
        echo "  Tip: run 'cabal update' to sync the Hackage package index"
      '';
    };

  # ============================================================
  # Elixir / Phoenix development shell
  # ============================================================
  # Provides a pinned Erlang + Elixir pair from nixpkgs.
  # nixpkgs' elixir packages already select a compatible OTP version,
  # so you don't need to worry about the Erlang/Elixir compatibility matrix.
  #
  # This shell is useful when you want:
  #   - A reproducible Elixir version without mise
  #   - CI parity: your CI can `nix develop .#elixir` for the same env
  #   - Multiple Elixir versions side-by-side (different devShells)
  # ============================================================
  elixir =
    let
      # Select the Elixir version. nixpkgs often provides several:
      # pkgs.elixir, pkgs.elixir_1_16, pkgs.elixir_1_17, etc.
      # The default `pkgs.elixir` tracks the latest stable.
      elixirPkg = pkgs.elixir;
    in
    pkgs.mkShell {
      name = "elixir-dev";

      packages = [
        elixirPkg           # elixir, iex, mix (OTP is a dependency, auto-included)
        pkgs.rebar3         # Erlang build tool (some hex packages need it)

        # ---- LSP (choose one or comment all if using `expert`) ----
        # pkgs.elixir-ls    # classic LSP: binary = elixir-ls
        # pkgs.lexical      # modern fast LSP: binary = lexical
        # pkgs.next-ls      # official direction: binary = nextls

        # ---- Database clients (for Ecto + Phoenix) ----
        pkgs.postgresql     # psql client for development
        # pkgs.sqlite        # if you use SQLite

        # ---- Node.js for Phoenix assets (esbuild/tailwind via mix) ----
        # Phoenix 1.7+ downloads its own esbuild/tailwind binaries via mix.
        # You only need Node if you have a custom JS pipeline.
        # pkgs.nodejs_22

        # ---- Linting / formatting ----
        # mix format is the built-in formatter (no separate binary needed)
        # credo runs via `mix credo` (installed as a dep in mix.exs)
      ];

      # Hex and Mix use HOME-relative directories. These env vars ensure
      # they're writable even in a nix shell:
      env = {
        # Hex and Mix write package caches to these directories.
        # Defaults (~/.hex, ~/.mix) are writable, which is what we want.
        # Explicitly setting them avoids accidental writes into read-only nix paths.
        MIX_HOME  = "$HOME/.mix";
        HEX_HOME  = "$HOME/.hex";
        # Enable Unicode display in the Erlang shell
        ERL_FLAGS = "+pc unicode";
      };

      shellHook = ''
        echo "Elixir dev shell"
        echo "  Elixir: $(elixir --version | grep Elixir)"
        echo "  OTP:    $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)"
        echo ""
        echo "  Tip: run 'mix deps.get' to fetch project dependencies"
        echo "  Tip: run 'mix phx.server' to start Phoenix"
      '';
    };

  # ============================================================
  # Rust development shell
  # ============================================================
  # Uses fenix to provide a pinned or dynamic Rust toolchain.
  #
  # fenix.fromToolchainFile reads rust-toolchain.toml from the project
  # root if it exists, giving each Rust project its own exact toolchain.
  # Without the file, it falls back to stable.
  #
  # This is SUPERIOR to the global rustup approach because:
  #   - The exact toolchain is reproducible from the lockfile
  #   - Different projects can have different toolchains simultaneously
  #   - `nix develop` gives you the right toolchain without `rustup override`
  # ============================================================
  rust =
    let
      # Try to read rust-toolchain.toml from the current directory.
      # builtins.pathExists checks at eval time (when you run `nix develop`).
      # If found, fenix builds exactly that toolchain; otherwise, stable.
      #
      # IMPORTANT: the path is evaluated relative to THIS FLAKE, not the
      # project you're developing. For project-specific toolchains, add a
      # flake.nix to that project, or use a fixed path here.
      toolchain = pkgsWithFenix.fenix.stable.withComponents [
        "rustc"
        "cargo"
        "rust-std"
        "rustfmt"
        "clippy"
        "rust-src"   # needed by rust-analyzer for std type info
      ];
    in
    pkgs.mkShell {
      name = "rust-dev";

      # nativeBuildInputs vs packages:
      # For a dev shell, the practical difference is small.
      # `nativeBuildInputs` is technically correct for build tools (compiler, linker)
      # because in cross-compilation they run on the HOST not the TARGET.
      # Using it also means they're added to PATH and linker search paths correctly.
      nativeBuildInputs = [
        toolchain                           # rustc, cargo, rustfmt, clippy
        pkgsWithFenix.fenix.stable.rust-analyzer  # LSP server
        pkgs.pkg-config                     # lets Cargo find system libraries
      ];

      buildInputs = [
        # C libraries commonly needed by Rust crates:
        pkgs.openssl        # reqwest, tls stacks
        pkgs.libiconv       # string encoding (harmless on Linux)
        pkgs.zlib           # compression
        pkgs.sqlite         # rusqlite, diesel sqlite
      ];

      env = {
        # rust-analyzer needs this to resolve std types
        RUST_SRC_PATH = "${pkgsWithFenix.fenix.stable.rust-src}/lib/rustlib/src/rust/library";
        # Show backtraces on panic (very useful during development)
        RUST_BACKTRACE = "1";
        # Linker flags for openssl (set automatically by openssl-sys crate
        # via pkg-config, but explicit doesn't hurt)
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      };

      shellHook = ''
        echo "Rust dev shell"
        echo "  rustc:  $(rustc --version)"
        echo "  cargo:  $(cargo --version)"
        echo "  ra:     $(rust-analyzer --version)"
        echo ""
        echo "  Tip: 'cargo watch -x run' for auto-reload on save"
        echo "  Tip: 'cargo nextest run' for faster test execution"
      '';
    };

  # ============================================================
  # Ruby / Rails development shell
  # ============================================================
  # Unlike Haskell/Elixir/Rust, Ruby projects almost always need
  # gems that are installed via `bundle install` into the project.
  # This shell focuses on:
  #   - Providing a Ruby binary + bundler
  #   - Providing C libraries that native gems compile against
  #   - Making LSP tooling available for the editor
  #
  # NOTE: For most Ruby/Rails work, you probably want mise (which you
  # already have) rather than this devShell. Use this devShell for:
  #   - CI environments where you want reproducible Ruby
  #   - Experimenting with a different Ruby version without changing mise
  #   - Projects where every contributor must have the exact same Ruby
  # ============================================================
  ruby =
    let
      # pkgs.ruby is MRI Ruby (the standard implementation).
      # pkgs.ruby_3_3, pkgs.ruby_3_2, etc. are pinned versions.
      rubyPkg = pkgs.ruby_3_3;
    in
    pkgs.mkShell {
      name = "ruby-dev";

      packages = [
        rubyPkg            # ruby, irb, gem
        pkgs.bundler       # bundle command

        # ---- LSP ----
        # ruby-lsp is a gem (installed via `gem install ruby-lsp` or Gemfile).
        # There IS a nixpkgs package: pkgs.rubyPackages.ruby-lsp
        # But it's often outdated and tied to the nixpkgs Ruby version.
        # For LSP in this shell: run `gem install ruby-lsp` after entering.
        # Your lsp.lua handles the rest automatically.

        # ---- Native extension dependencies ----
        # Gems with C extensions (nokogiri, bcrypt, pg, mysql2, etc.)
        # need these at compile time. Bundle install will find them via
        # the PKG_CONFIG_PATH set in env below.
        pkgs.pkg-config
        pkgs.openssl
        pkgs.libxml2
        pkgs.libxslt
        pkgs.zlib
        pkgs.readline
        pkgs.libyaml       # psych (Ruby's YAML library) native extension
        pkgs.postgresql    # pg gem — libpq headers
        # pkgs.sqlite      # sqlite3 gem

        # ---- Node.js for Rails asset pipeline ----
        pkgs.nodejs_22     # rails assets:precompile, yarn
        pkgs.yarn

        # ---- Testing ----
        # rspec, minitest, etc. are gems — installed via bundle.
        # This binary is useful for command-line test running:
        # pkgs.rubyPackages.minitest  # if available
      ];

      env = {
        # Point bundler at a writable gem home so it doesn't try to write
        # into the nix store (which is read-only).
        BUNDLE_PATH      = ".bundle/gems";  # install gems locally in the project
        GEM_HOME         = ".bundle/gems";
        # Disable the bundler version check that sometimes causes issues in nix
        BUNDLE_DISABLE_VERSION_CHECK = "1";

        # PKG_CONFIG_PATH makes pkg-config aware of nix-provided libraries
        # so `bundle install` can compile native extensions correctly.
        PKG_CONFIG_PATH  = pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
          pkgs.openssl pkgs.libxml2 pkgs.libxslt pkgs.zlib
          pkgs.readline pkgs.libyaml pkgs.postgresql
        ];
      };

      shellHook = ''
        echo "Ruby dev shell"
        echo "  Ruby:    $(ruby --version)"
        echo "  Bundler: $(bundle --version)"
        echo ""
        echo "  Tip: run 'bundle install' to install project gems"
        echo "  Tip: run 'gem install ruby-lsp' for LSP support"
        echo "  Tip: run 'bundle exec rails server' to start Rails"
      '';
    };
}
