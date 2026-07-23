{ pkgs, ... }:

# ============================================================
# Elixir / Phoenix development shell
# ============================================================
# Provides a pinned Erlang + Elixir pair from nixpkgs.
# nixpkgs' elixir packages already select a compatible OTP version,
# so you don't need to worry about the Erlang/Elixir compatibility matrix.
#
# This shell is useful when you want:
#   - A reproducible Elixir version (this replaces mise)
#   - CI parity: your CI can `nix develop .#elixir` for the same env
#   - Multiple Elixir versions side-by-side (different devShells)
# ============================================================
let
  # Select the Elixir version. nixpkgs often provides several:
  # pkgs.elixir, pkgs.elixir_1_16, pkgs.elixir_1_17, etc.
  # The default `pkgs.elixir` tracks the latest stable.
  elixirPkg = pkgs.elixir;
in
pkgs.mkShell {
  name = "elixir-dev";

  packages = [
    elixirPkg # elixir, iex, mix (OTP is a dependency, auto-included)
    pkgs.rebar3 # Erlang build tool (some hex packages need it)

    # ---- LSP (choose one or comment all if using `expert`) ----
    # pkgs.elixir-ls    # classic LSP: binary = elixir-ls
    # pkgs.lexical      # modern fast LSP: binary = lexical
    # pkgs.next-ls      # official direction: binary = nextls

    # ---- Database clients (for Ecto + Phoenix) ----
    pkgs.postgresql # psql client for development
    # pkgs.sqlite        # if you use SQLite

    # ---- Node.js for Phoenix assets (esbuild/tailwind via mix) ----
    # Phoenix 1.7+ downloads its own esbuild/tailwind binaries via mix.
    # You only need Node if you have a custom JS pipeline.
    # pkgs.nodejs_22

    # ---- Linting / formatting ----
    # mix format is the built-in formatter (no separate binary needed)
    # credo runs via `mix credo` (installed as a dep in mix.exs)
  ];

  # Hex and Mix use HOME-relative directories. These env vars ensure
  # they're writable even in a nix shell:
  env = {
    # Hex and Mix write package caches to these directories.
    # Defaults (~/.hex, ~/.mix) are writable, which is what we want.
    # Explicitly setting them avoids accidental writes into read-only nix paths.
    MIX_HOME = "$HOME/.mix";
    HEX_HOME = "$HOME/.hex";
    # Enable Unicode display in the Erlang shell
    ERL_FLAGS = "+pc unicode";
  };

  shellHook = ''
    echo "Elixir dev shell"
    echo "  Elixir: $(elixir --version | grep Elixir)"
    echo "  OTP:    $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)"
    echo ""
    echo "  Tip: run 'mix deps.get' to fetch project dependencies"
    echo "  Tip: run 'mix phx.server' to start Phoenix"
  '';
}
