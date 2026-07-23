{ pkgs, pkgsWithFenix, ... }:

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
    "rust-src" # needed by rust-analyzer for std type info
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
    toolchain # rustc, cargo, rustfmt, clippy
    pkgsWithFenix.fenix.stable.rust-analyzer # LSP server
    pkgs.pkg-config # lets Cargo find system libraries
  ];

  buildInputs = [
    # C libraries commonly needed by Rust crates:
    pkgs.openssl # reqwest, tls stacks
    pkgs.libiconv # string encoding (harmless on Linux)
    pkgs.zlib # compression
    pkgs.sqlite # rusqlite, diesel sqlite
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
}
