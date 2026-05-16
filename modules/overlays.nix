{ inputs, ... }:

# ============================================================
# Overlays — extending and modifying the package set
# ============================================================
#
# This file is a REFERENCE/TUTORIAL for overlays. It is imported in
# home.nix but only activates the overlays you uncomment. The comments
# explain the concept thoroughly so you understand what's happening
# when you reach for an overlay in future work.
#
# ============================================================
# WHAT IS AN OVERLAY?
# ============================================================
#
# nixpkgs is a giant attribute set: { git = ...; neovim = ...; ... }
# An overlay is a FUNCTION that modifies this set. Its signature is:
#
#   final: prev: { ... }
#
# Where:
#   `prev` — the package set BEFORE this overlay (and before any
#            overlays later in the list). Use this to access the
#            original package when you want to modify it.
#   `final` — the package set AFTER ALL overlays are applied.
#             Use this when your package depends on something that
#             might itself be overlaid.
#
# Nix applies overlays as a fixed-point computation:
#   pkgs = fix (foldl' (acc: overlay: overlay acc acc) nixpkgs overlays)
# In practice: `final` lets you reference other packages correctly
# even if they were modified by a later overlay.
#
# ============================================================
# THREE WAYS TO APPLY OVERLAYS
# ============================================================
#
# 1. In flake.nix (what we do in this config):
#    pkgs = import nixpkgs { overlays = [ myOverlay ]; };
#
# 2. In nixpkgs config (~/.config/nixpkgs/overlays/default.nix):
#    Used in non-flake setups.
#
# 3. Via nixpkgs.overlays in NixOS/home-manager options:
#    nixpkgs.overlays = [ myOverlay ];
#    (NixOS-specific — doesn't apply here on Debian standalone HM)
#
# ============================================================
# OVERLAY EXAMPLES (progressively more complex)
# ============================================================
#
# Example 1 — Add a package not in nixpkgs:
# ─────────────────────────────────────────
#   final: prev: {
#     my-script = prev.writeShellScriptBin "my-script" ''
#       echo "Hello from a nix-packaged script"
#     '';
#   }
#
# `writeShellScriptBin` creates a derivation that installs the script
# as a binary. You can then add `pkgs.my-script` to home.packages.
#
# Example 2 — Override a package's source (upgrade/pin a version):
# ─────────────────────────────────────────────────────────────────
#   final: prev: {
#     neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (old: rec {
#       version = "0.10.2";
#       src = prev.fetchFromGitHub {
#         owner = "neovim";
#         repo  = "neovim";
#         rev   = "v${version}";
#         hash  = "sha256-AAAA...";  # get with: nix-prefetch-github neovim neovim --rev v0.10.2
#       };
#     });
#   }
#
# Example 3 — Override build options:
# ─────────────────────────────────────
#   final: prev: {
#     # Build ripgrep with the PCRE2 backend enabled
#     ripgrep = prev.ripgrep.override { withPCRE2 = true; };
#   }
#
# Example 4 — Add a flake input's packages into pkgs:
# ────────────────────────────────────────────────────
#   # This is how fenix.overlays.default works — it adds pkgs.fenix.*
#   final: prev: {
#     fenix = inputs.fenix.packages.${prev.system};
#   }
#
# Example 5 — Pin a package to an older nixpkgs revision:
# ─────────────────────────────────────────────────────────
#   # Sometimes nixpkgs-unstable breaks a package you rely on.
#   # Pin that one package to stable while keeping everything else on unstable.
#   final: prev:
#   let
#     stable = import inputs.nixpkgs-stable { system = prev.system; };
#   in {
#     broken-package = stable.broken-package;
#   }
#   # Requires adding nixpkgs-stable as a flake input.
#
# ============================================================
# WHEN TO USE OVERLAYS vs OTHER APPROACHES
# ============================================================
#
#   Use overlays when:
#     • You want the modified package available EVERYWHERE in your
#       home config without passing it explicitly.
#     • You're fixing a nixpkgs package that's broken or outdated.
#     • You're packaging something new to contribute back to nixpkgs.
#
#   Use `pkgs.callPackage ./my-package.nix {}` directly when:
#     • Only one module needs the package.
#     • You don't want to affect the global pkgs set.
#
#   Use `home.packages = [ myDrv ]` directly when:
#     • You want a quick one-off binary without a full nix package.
#     • The derivation is simple (writeShellScriptBin, symlinkJoin, etc.)
#
# ============================================================

{
  # When using overlays in a standalone HM setup (Debian), we configure
  # them via nixpkgs.overlays. This option applies to the pkgs instance
  # that Home Manager uses internally.
  nixpkgs.overlays = [

    # ---- fenix Rust toolchain overlay ----
    # Adds `pkgs.fenix.*` to the package set.
    # This is already applied to pkgsWithFenix in flake.nix;
    # uncommenting here would make it available globally in all modules.
    # Uncomment if you want `pkgs.fenix` available without pkgsWithFenix:
    # inputs.fenix.overlays.default

    # ---- Example: pin a specific neovim version ----
    # Uncomment and adjust if nixpkgs-unstable ships a broken neovim:
    # (final: prev: {
    #   neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (old: {
    #     version = "0.10.1";
    #     src = prev.fetchFromGitHub {
    #       owner = "neovim"; repo = "neovim"; rev = "v0.10.1";
    #       hash = "sha256-CHANGE_ME";
    #     };
    #   });
    # })

    # ---- Example: add a custom script as a package ----
    # (final: prev: {
    #   my-dev-scripts = prev.symlinkJoin {
    #     name = "my-dev-scripts";
    #     paths = [
    #       (prev.writeShellScriptBin "ghstack" ''
    #         # Wrapper around git that prefixes branch names with your username
    #         git "$@"
    #       '')
    #     ];
    #   };
    # })
  ];
}
