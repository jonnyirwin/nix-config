{ pkgs }:

# Per-stack development environments.
#
#   One-off:      nix develop ~/git/nix#ruby
#   Per-project:  echo "use flake ~/git/nix#ruby" > .envrc && direnv allow
#
# These replace mise and ghcup: a project's toolchain is selected by its .envrc
# and pinned by this flake's lock file, rather than by a global version manager.
# If a project has its own flake with a devShell, use `use flake` instead.
#
# `pkgs` carries the fenix overlay (see flake.nix), so rust.nix reads
# pkgs.fenix.* directly rather than needing a second package set.

{
  haskell = import ./haskell.nix { inherit pkgs; };
  elixir = import ./elixir.nix { inherit pkgs; };
  rust = import ./rust.nix { inherit pkgs; };
  ruby = import ./ruby.nix { inherit pkgs; };
}
