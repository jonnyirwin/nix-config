{ config, lib, pkgs, ... }:

# Aseprite — pixel art / animated sprite editor.
#
# nixpkgs marks it unfree: the source is public, but the license doesn't
# permit redistributing built binaries, so Hydra never builds it and every
# machine compiles it locally from the upstream GitHub source (skia UI
# backend + bundled libs) instead of fetching a pre-built artifact. That's
# already "from source" — no overlay or custom derivation needed, just
# `config.allowUnfree = true` (set globally in flake.nix) plus the package.
let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.aseprite ];
  };
}
