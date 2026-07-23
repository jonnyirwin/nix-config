# home.shellAliases is propagated to every shell HM manages, so these survive
# adding bash or zsh later. Fish-specific things live in fish.nix.
{
  home.shellAliases = {
    # Modern CLI replacements
    ls = "eza --icons";
    ll = "eza -la --icons --git";
    lt = "eza --tree --level=2 --icons";
    cat = "bat --style=plain";
    grep = "rg";
    find = "fd";
    top = "btop";

    # Rebuild this flake
    nrs = "sudo nixos-rebuild switch --flake ~/git/nix#optiplex";
    nrt = "sudo nixos-rebuild test --flake ~/git/nix#optiplex";
    nrb = "nixos-rebuild build --flake ~/git/nix#optiplex && nvd diff /run/current-system ./result";

    # Run or enter any nixpkgs package without installing it
    nxs = "nix shell nixpkgs#";
    nxr = "nix run nixpkgs#";

    # Rails
    killrails = "pkill -f rails; pkill -f puma; rm -f tmp/pids/server.pid";
    railsdebug = "env RUBY_DEBUG_OPEN=true RUBY_DEBUG_PORT=38698 bundle exec rails s";
  };
}
