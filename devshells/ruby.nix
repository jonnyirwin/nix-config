{ pkgs, ... }:

# ============================================================
# Ruby / Rails development shell
# ============================================================
# Unlike Haskell/Elixir/Rust, Ruby projects almost always need
# gems that are installed via `bundle install` into the project.
# This shell focuses on:
#   - Providing a Ruby binary + bundler
#   - Providing C libraries that native gems compile against
#   - Making LSP tooling available for the editor
#
#
# This is now the only source of a Ruby runtime — mise is gone. Select it per
# project with `echo "use flake ~/git/nix#ruby" > .envrc && direnv allow`, or
# give the project its own flake if it needs a different Ruby version.
# ============================================================
let
  # pkgs.ruby is MRI Ruby (the standard implementation).
  # pkgs.ruby_3_3, pkgs.ruby_3_2, etc. are pinned versions.
  rubyPkg = pkgs.ruby_3_3;
in
pkgs.mkShell {
  name = "ruby-dev";

  packages = [
    rubyPkg # ruby, irb, gem
    pkgs.bundler # bundle command

    # ---- LSP ----
    # lua/plugins/lsp.lua prefers `bundle exec ruby-lsp` when the gem is in
    # Gemfile.lock and falls back to a global `ruby-lsp`. With mise gone
    # there is no global gem install, so this shell provides the fallback.
    pkgs.rubyPackages.ruby-lsp

    # ---- Native extension dependencies ----
    # Gems with C extensions (nokogiri, bcrypt, pg, mysql2, etc.)
    # need these at compile time. Bundle install will find them via
    # the PKG_CONFIG_PATH set in env below.
    pkgs.pkg-config
    pkgs.openssl
    pkgs.libxml2
    pkgs.libxslt
    pkgs.zlib
    pkgs.readline
    pkgs.libyaml # psych (Ruby's YAML library) native extension
    pkgs.postgresql # pg gem — libpq headers
    # pkgs.sqlite      # sqlite3 gem

    # ---- Node.js for Rails asset pipeline ----
    pkgs.nodejs_22 # rails assets:precompile, yarn
    pkgs.yarn

    # ---- Testing ----
    # rspec, minitest, etc. are gems — installed via bundle.
    # This binary is useful for command-line test running:
    # pkgs.rubyPackages.minitest  # if available
  ];

  env = {
    # Point bundler at a writable gem home so it doesn't try to write
    # into the nix store (which is read-only).
    BUNDLE_PATH = ".bundle/gems"; # install gems locally in the project
    GEM_HOME = ".bundle/gems";
    # Disable the bundler version check that sometimes causes issues in nix
    BUNDLE_DISABLE_VERSION_CHECK = "1";

    # PKG_CONFIG_PATH makes pkg-config aware of nix-provided libraries
    # so `bundle install` can compile native extensions correctly.
    PKG_CONFIG_PATH = pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
      pkgs.openssl
      pkgs.libxml2
      pkgs.libxslt
      pkgs.zlib
      pkgs.readline
      pkgs.libyaml
      pkgs.postgresql
    ];
  };

  shellHook = ''
    echo "Ruby dev shell"
    echo "  Ruby:    $(ruby --version)"
    echo "  Bundler: $(bundle --version)"
    echo ""
    echo "  Tip: run 'bundle install' to install project gems"
    echo "  Tip: ruby-lsp is already on PATH; run 'bundle install' first"
    echo "  Tip: run 'bundle exec rails server' to start Rails"
  '';
}
