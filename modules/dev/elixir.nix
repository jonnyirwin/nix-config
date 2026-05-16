{ config, pkgs, lib, ... }:

# ============================================================
# Elixir / Erlang global tooling
# ============================================================
#
# Runtime management: mise vs Nix
# ────────────────────────────────
# Your mise.toml pins:
#   erlang = "latest"
#   elixir = "latest"
#
# mise downloads and manages Erlang/OTP and Elixir versions from ASDF
# sources, placing them in ~/.local/share/mise/installs/. This is
# analogous to rbenv or nvm for those ecosystems.
#
# You could replace mise with nix for Elixir/Erlang management, but
# the trade-off is real:
#
#   mise pros: `mix local.hex`, `mix archive.install`, and other mix
#   tasks that modify the Elixir installation work normally because
#   the install is in a writable directory. The nix store is read-only,
#   which complicates these workflows.
#
#   nix devShells pros: perfectly reproducible, no mise needed,
#   works on any machine with nix. See devShells.nix where the Elixir
#   shell uses pkgs.elixir and pkgs.erlang directly.
#
# Recommended split (what this module does):
#   • mise manages the RUNTIME (the `elixir` and `iex` commands)
#   • This module installs supporting tools that work at any version
#   • devShells.nix provides a hermetic env for specific projects
#
# ============================================================
# The `expert` LSP
# ─────────────────
# Your lsp.lua configures the Elixir LSP as:
#   cmd = { "expert", "--stdio" }
#
# The binary `expert` is not a well-known package in nixpkgs. It may be:
#   a) A custom wrapper you built manually
#   b) A pre-release version of the new official Elixir LSP
#   c) A renamed `next-ls` or `lexical` binary
#
# Alternatives available in nixpkgs:
#   pkgs.elixir-ls   → `elixir-ls` binary, stable, widely used
#   pkgs.next-ls     → `nextls` binary, newer, requires Elixir 1.15+
#   pkgs.lexical     → `lexical` binary, fast, good completion
#
# For now, `expert` is NOT installed here — ensure it's on your PATH
# via whatever method you used to install it originally.
# To switch to elixir-ls, change lsp.lua: cmd = { "elixir-ls" }
# ============================================================

{
  home.packages = with pkgs; [

    # ---- Linting ----
    # credo is the Elixir static analysis tool (like hlint for Haskell).
    # It runs as a mix task (`mix credo`), but having the escript binary
    # available globally is useful for CI and editor integration.
    # Note: credo is best installed per-project via mix.exs deps. Installing
    # it globally here means you always have a fallback.
    # Uncomment if available in your nixpkgs revision:
    # elixir-credo

    # ---- Build / project tooling ----
    # rebar3 is the Erlang build tool, needed for some Hex packages that
    # contain Erlang NIFs. mise-installed Elixir bundles its own rebar3,
    # but having it globally ensures compatibility.
    rebar3

    # ---- Elixir Language Server alternatives ----
    # Uncomment ONE of these if you want to switch from `expert`:
    # elixir-ls   # classic, stable: `elixir-ls` binary
    # lexical     # modern, fast: `lexical` binary
    # next-ls     # new official direction: `nextls` binary

    # ---- Database migration tooling ----
    # ecto_sql migration commands run via mix, but for schema introspection
    # you'll want the underlying DB client too. Uncomment as needed:
    # postgresql  # psql client
  ];

  # ============================================================
  # IMPORTANT: Elixir and Erlang are NOT installed here.
  # ============================================================
  # They are managed by mise (see ~/.dotfiles/mise/.config/mise/config.toml).
  # To update to a new Elixir version: mise use elixir@1.17.0
  #
  # For hermetic per-project environments, use:
  #   echo "use flake /home/jonny/git/nix#elixir" > .envrc
  #   direnv allow
  # The devShell pins exact Elixir + Erlang versions from nixpkgs.
  # ============================================================
}
