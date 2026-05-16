{ config, pkgs, lib, ... }:

# ============================================================
# Ruby global tooling
# ============================================================
#
# Ruby + Nix: the fundamental tension
# ─────────────────────────────────────
# Ruby's ecosystem relies heavily on Bundler: most tools (rubocop,
# ruby-lsp, haml-lint, erb-lint) are gems installed per-project
# via `bundle install`. This is by design — they version-lock with
# the application.
#
# Nix can install Ruby globally, but:
#   • `gem install` and `bundle install` write to a directory inside
#     the Nix store (read-only), requiring BUNDLE_PATH or GEM_HOME
#     overrides.
#   • mise is better at managing multiple Ruby versions (matching
#     .ruby-version or .tool-versions files per project), which is
#     what you're already doing.
#
# Strategy: mise manages the Ruby runtime; Nix supplies support tools.
#
# ============================================================
# ruby-lsp and LSP integration
# ─────────────────────────────
# Your lsp.lua has sophisticated ruby-lsp detection logic:
#
#   1. If ruby-lsp is in Gemfile.lock → use `bundle exec ruby-lsp`
#   2. Otherwise → use the global `ruby-lsp` binary
#
# This works perfectly with mise because:
#   • mise shims the `ruby` and `gem` executables
#   • When you run `gem install ruby-lsp`, it installs into mise's
#     Ruby version directory (e.g. ~/.local/share/mise/installs/ruby/3.3.5/gems/)
#   • The shims ensure the right `ruby-lsp` is found for the active Ruby version
#
# Install ruby-lsp globally for the fallback:
#   mise exec ruby -- gem install ruby-lsp
#
# This is NOT done via Nix because:
#   a) ruby-lsp versions must match the Ruby version — mise handles this
#   b) The gem needs write access to its install directory at runtime
#      (for ruby-lsp's add-on discovery and cache)
#   c) nixpkgs.rubyPackages.ruby-lsp exists but is often behind the
#      gem release and requires matching the nixpkgs Ruby exactly
# ============================================================
#
# rubocop: why it's disabled in your neovim config
# ──────────────────────────────────────────────────
# Your lsp.lua explicitly disables the rubocop LSP client:
#
#   vim.lsp.config('rubocop', { filetypes = {} })
#
# This is because ruby-lsp already embeds RuboCop integration
# (via ruby-lsp's addon system). Running both causes duplicate
# diagnostics. Leave rubocop disabled at the LSP level; ruby-lsp
# surfaces rubocop errors transparently.
# ============================================================

{
  home.packages = with pkgs; [

    # ---- Global scripting support ----
    # These are useful even without a project Gemfile.

    # bundler itself — in case you need it before mise shims are active
    # (e.g. in a fresh shell before cd-ing into a project directory).
    # Normally provided by mise-managed Ruby.
    # Uncomment if you want a fallback:
    # bundler

    # ---- Static analysis (standalone, version-agnostic) ----
    # haml-lint is a linter for HAML templates. Your none-ls.lua
    # uses `bundle exec haml-lint` (project-local), but having a
    # global fallback is useful for one-off linting.
    # Note: haml-lint may not be in nixpkgs — it's primarily a gem.
    # Check: nix search nixpkgs haml-lint

    # ---- Database tools for Rails development ----
    # postgresql  # psql client for Rails/ActiveRecord
    # sqlite      # sqlite3 for development databases

    # ---- Build dependencies for native extensions ----
    # Some gems compile C extensions. These libraries are commonly needed:
    libxml2    # nokogiri
    libxslt    # nokogiri
    zlib       # common compression library
    readline   # irb / pry readline support
    openssl    # net-http, openssl gem
  ];

  # ============================================================
  # Mise integration
  # ============================================================
  # Your mise config (mise/.config/mise/config.toml) sets:
  #   ruby = "3"
  #   settings.idiomatic_version_file_enable_tools = ["ruby"]
  #
  # The `idiomatic_version_file` setting means mise reads .ruby-version
  # files in project directories and switches Ruby automatically —
  # the same behaviour as rbenv.
  #
  # Useful mise commands for Ruby:
  #   mise install ruby@3.3.5    — install a specific version
  #   mise use ruby@3.3.5        — set version in current project's .tool-versions
  #   mise use -g ruby@3.3.5     — set as global default
  #   mise exec ruby -- gem list — list gems for the active Ruby version
  # ============================================================

  # ============================================================
  # Setting GEM_HOME for tools that need it
  # ============================================================
  # If you run `gem install` outside of mise management (e.g. for
  # global scripts), gems land in $GEM_HOME. The default is often
  # system-wide (needs sudo) or inside a nix path (read-only).
  #
  # Setting GEM_HOME to a writable user path avoids both problems:
  # home.sessionVariables = {
  #   GEM_HOME = "${config.home.homeDirectory}/.gems";
  #   GEM_PATH = "${config.home.homeDirectory}/.gems";
  # };
  # home.sessionPath = [ "${config.home.homeDirectory}/.gems/bin" ];
  #
  # In practice, with mise, this is unnecessary — mise manages its own
  # gem directories per Ruby version. Only uncomment if you run into
  # `gem install` permission errors outside mise-managed contexts.
  # ============================================================
}
