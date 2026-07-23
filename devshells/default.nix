{ pkgs, pkgsWithFenix }:

# Per-stack development environments.
#
#   One-off:      nix develop ~/git/nix#ruby
#   Per-project:  echo "use flake ~/git/nix#ruby" > .envrc && direnv allow
#
# These replace mise and ghcup: a project's toolchain is selected by its .envrc
# and pinned by this flake's lock file, rather than by a global version manager.
# If a project has its own flake with a devShell, use `use flake` instead.

let
  args = { inherit pkgs pkgsWithFenix; };
in
{
  haskell = import ./haskell.nix args;
  elixir = import ./elixir.nix args;
  rust = import ./rust.nix args;
  ruby = import ./ruby.nix args;
}
