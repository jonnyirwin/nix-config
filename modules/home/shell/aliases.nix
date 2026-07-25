{ config, osConfig, ... }:

# home.shellAliases is propagated to every shell HM manages, so these survive
# adding bash or zsh later. Fish-specific things live in fish.nix.

let
  # Derived, not hardcoded: on a second machine these would otherwise rebuild
  # optiplex from a path that may not exist.
  flake = "${config.jonny.flakePath}#${osConfig.networking.hostName}";
in
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

    # Rebuild this flake for *this* host
    nrs = "sudo nixos-rebuild switch --flake ${flake}";
    nrt = "sudo nixos-rebuild test --flake ${flake}";
    nrb = "nixos-rebuild build --flake ${flake} && nvd diff /run/current-system ./result";
    # Stage as the *next* boot's default without activating live — the safe
    # path for display-manager/initrd changes that a `switch` would otherwise
    # apply mid-session. Follow with a reboot.
    nrboot = "sudo nixos-rebuild boot --flake ${flake}";

    # Run or enter any nixpkgs package without installing it
    nxs = "nix shell nixpkgs#";
    nxr = "nix run nixpkgs#";

    # Rails
    killrails = "pkill -f rails; pkill -f puma; rm -f tmp/pids/server.pid";
    railsdebug = "env RUBY_DEBUG_OPEN=true RUBY_DEBUG_PORT=38698 bundle exec rails s";
  };
}
