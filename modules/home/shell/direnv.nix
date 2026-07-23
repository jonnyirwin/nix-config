{
  # This is what replaces mise: `cd` into a project with an .envrc containing
  #   use flake ~/git/nix#ruby
  # and its toolchain is on PATH. nix-direnv caches the devShell evaluation so
  # re-entering is instant.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
