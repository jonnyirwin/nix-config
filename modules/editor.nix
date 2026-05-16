{ config, pkgs, lib, ... }:

# ============================================================
# Neovim + Language Server Protocol tooling
# ============================================================
#
# Strategy: Nix installs the BINARY, your dotfiles own the CONFIGURATION.
#
#   • programs.neovim.enable installs the neovim binary from nixpkgs.
#   • home.packages installs every LSP server, formatter, and linter
#     so they are on PATH when neovim starts — your existing Lua config
#     in ~/.dotfiles/neovim/ finds them without any changes.
#   • xdg.configFile."nvim" symlinks ~/.config/nvim → your dotfiles,
#     so lazy.nvim, your plugin configs, and all Lua files stay exactly
#     where they are. Edit them in the dotfiles repo; no `hm switch` needed.
#
# What this module does NOT manage:
#   • lazy.nvim plugins — those are downloaded/updated by lazy itself
#   • The Lua plugin configs in lua/plugins/*.lua — edit them directly
#   • Per-project LSP wrappers (e.g. `bundle exec ruby-lsp`) — those are
#     handled inside your Lua configs, which detect Gemfile.lock etc.
#
# ============================================================
# LSP server → nixpkgs package mapping (what's installed and why)
# ============================================================
#
#   ruby_lsp       → via `gem install ruby-lsp` (see modules/dev/ruby.nix)
#                    NOT installed globally via nix because ruby-lsp must
#                    match the project's Ruby version (managed by mise).
#                    Your lsp.lua already handles `bundle exec ruby-lsp`
#                    for projects that have it in Gemfile.lock.
#
#   expert (Elixir) → NOT in nixpkgs. This is a binary you have installed
#                    separately (likely a custom build or a pre-release tool).
#                    See modules/dev/elixir.nix for alternatives and notes.
#
#   ts_ls           → pkgs.typescript-language-server
#   eslint          → pkgs.vscode-langservers-extracted
#   hls (Haskell)   → via ghcup (see modules/dev/haskell.nix for why)
#   lua_ls          → pkgs.lua-language-server
#   nil  (Nix LSP)  → pkgs.nil
# ============================================================

{
  programs.neovim = {
    enable    = true;
    withNodeJs = true;   # enables Node.js provider (needed by some plugins)
    withPython3 = false; # set to true if you use Python-backed plugins
    withRuby   = false;  # ruby provider — ruby-lsp doesn't need this

    # defaultEditor makes `$EDITOR` and `$VISUAL` point to nvim.
    # Also sets `vi` and `vim` aliases to nvim.
    defaultEditor = true;

    # We do NOT set `plugins` here — that would use nix-managed plugins,
    # conflicting with lazy.nvim. Leave plugin management entirely to lazy.
    # We do NOT set `extraConfig` — your init.lua in dotfiles handles everything.
  };

  # Symlink ~/.config/nvim → your dotfiles neovim config.
  # mkOutOfStoreSymlink creates a live symlink (not a nix store copy), so:
  #   - You can edit Lua files in ~/.dotfiles/neovim/ and see changes immediately
  #   - lazy.nvim reads/writes its lock file and plugin cache as normal
  #   - No `home-manager switch` needed to pick up Lua config changes
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/neovim/.config/nvim";

  # ----------------------------------------------------------
  # LSP servers, formatters, and linters
  # ----------------------------------------------------------
  # All of these end up in ~/.nix-profile/bin/, which is on PATH.
  # Neovim's vim.lsp.enable('server') will find them there.
  home.packages = with pkgs; [

    # ---- Lua ----
    # lua-language-server is used for editing your own Lua plugin configs.
    lua-language-server
    stylua              # Lua formatter, used by none-ls.lua (null_ls.builtins.formatting.stylua)

    # ---- Nix ----
    # nil — the Nix Language Server. Provides:
    #   - Completion (package names, function args, module options)
    #   - Go-to-definition (jump to where a package is defined in nixpkgs)
    #   - Hover documentation
    #   - Find references
    #   - Formatting (delegates to alejandra, configured in modules/neovim-lsp-additions.lua)
    # Wire it up in your lsp.lua — see modules/neovim-lsp-additions.lua.
    nil

    # nixd is an alternative Nix LSP with better NixOS/home-manager option
    # completion (it can complete module options like `services.nginx.*`).
    # Trade-off: heavier resource usage than nil.
    # Uncomment to use instead of (or alongside) nil:
    # nixd

    # alejandra — opinionated Nix formatter. Already configured in
    # your none-ls.lua (null_ls.builtins.formatting.alejandra).
    # Running: null-ls calls it automatically on <leader>lf in .nix files.
    alejandra

    # statix — static analyser and linter for Nix expressions.
    # Catches common mistakes:
    #   - Unused variables in let bindings
    #   - Redundant patterns
    #   - Deprecated Nix idioms (e.g. `with pkgs; [ ... ]` anti-patterns)
    # nil_ls integrates statix as diagnostics automatically when it's on PATH.
    # You can also run it manually: statix check . / statix fix .
    statix

    # deadnix — finds dead code (unused variables, unused function arguments)
    # in Nix files. Complements statix. nil_ls runs it too when on PATH.
    # Manual: deadnix --edit file.nix (auto-removes dead code)
    deadnix

    # ---- TypeScript / JavaScript ----
    # typescript-language-server provides ts_ls (your lsp.lua: vim.lsp.enable('ts_ls'))
    typescript-language-server
    # vscode-langservers-extracted bundles the eslint language server,
    # html, css, and json LSPs from VSCode. Your lsp.lua enables 'eslint'.
    vscode-langservers-extracted
    # prettier used by none-ls.lua for formatting JS/TS/CSS/HTML/YAML/etc.
    prettier

    # ---- CSS / SCSS ----
    # stylelint is referenced in none-ls.lua for CSS diagnostics.
    # Install globally so it's available for projects that don't bundle it.
    stylelint

    # ---- Markdown ----
    # markdownlint-cli: both diagnostics and formatting in none-ls.lua.
    markdownlint-cli

    # ---- General / misc ----
    # tree-sitter CLI — used by nvim-treesitter to compile grammars.
    # Without this, grammars are compiled at runtime (slower first launch).
    tree-sitter

    # ---- Neovim itself needs these at runtime ----
    # Some neovim plugins shell out to these:
    ripgrep  # telescope live grep
    fd       # telescope file finder

    # ---- Database tooling (for vim-dadbod) ----
    # Install the database clients you actually use:
    # postgresql  # psql
    # mysql80     # mysql
    # sqlite      # sqlite3
  ];
}
