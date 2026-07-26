{ inputs, pkgs, ... }:

# Terminal RSS reader, built from its own flake (see inputs.rss-is-terminal).
#
# No config lives here on purpose: the app owns
# ~/.config/rss_is_terminal/config.toml and its feed database at
# ~/.local/share/rss_is_terminal/rss.db, both of which it writes itself. Putting
# the TOML under Home Manager would make it read-only and break the in-app
# settings.

{
  home.packages = [
    inputs.rss-is-terminal.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
