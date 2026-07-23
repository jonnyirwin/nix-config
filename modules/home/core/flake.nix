{ config, lib, ... }:

# Where this configuration is checked out.
#
# It matters functionally, not just cosmetically: the Neovim config reaches
# ~/.config/nvim by out-of-store symlink into this repo, so a machine that
# clones it elsewhere would silently get no nvim config at all. Everything that
# needs the path reads it from here.

{
  options.jonny.flakePath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/git/nix";
    description = ''
      Absolute path to this flake's working tree on the local machine.
      Override per host if you clone it somewhere else.
    '';
  };
}
