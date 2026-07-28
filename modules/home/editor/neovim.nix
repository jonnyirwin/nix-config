{ config, pkgs, ... }:

# Neovim: Nix owns the binary, the plugin *runtime* deps, and every external
# tool. The Lua stays Lua.
#
# Two deliberate choices:
#
#   1. No nixvim. Its options layer forces anything it doesn't model down into
#      extraConfigLua, which is most of this config.
#
#   2. ~/.config/nvim is an out-of-store symlink into this repo, not a store
#      copy. That keeps the edit-and-`:source` loop, and lets lazy.nvim write
#      lazy-lock.json back into a git-tracked file. It is the one config in this
#      flake that is not store-deployed, and it is a symlink to *this* repo —
#      not to a second dotfiles repo you have to clone separately.
#
# mason is deliberately absent (and never was in this config): tools come from
# extraPackages below, which puts them on nvim's PATH only, so the global
# profile stays clean.

let
  configPath = "${config.jonny.flakePath}/modules/home/editor/nvim";

  # Treesitter parsers, prebuilt from nixpkgs. This replaces the runtime
  # `require('nvim-treesitter').install(...)` block plus `build = ":TSUpdate"`
  # in lua/plugins/treesitter.lua, which compiled 24 grammars on first launch
  # and needed a C toolchain present.
  #
  # They are dropped into ~/.local/share/nvim/site, which is on the default
  # runtimepath, rather than passed to programs.neovim.plugins — that option
  # makes HM generate its own ~/.config/nvim/init.lua, which cannot coexist
  # with symlinking the whole nvim directory below.
  #
  # Only parser/ is linked, not queries/: nvim-treesitter ships its own query
  # files and lazy.nvim installs those, so linking the grammars' copies too
  # would stack duplicate highlight captures.
  treesitterGrammars = pkgs.symlinkJoin {
    name = "nvim-treesitter-grammars";
    paths = map pkgs.vimPlugins.nvim-treesitter.grammarToPlugin (
      # angular and ssh_config have no nixpkgs grammar; nvim-treesitter still
      # builds those two on demand via the tree-sitter CLI in extraPackages.
      with pkgs.tree-sitter-grammars; [
        tree-sitter-bash
        tree-sitter-c-sharp
        tree-sitter-css
        tree-sitter-csv
        tree-sitter-devicetree
        tree-sitter-dockerfile
        tree-sitter-elixir
        tree-sitter-elm
        tree-sitter-embedded-template
        tree-sitter-gitignore
        tree-sitter-haskell
        tree-sitter-html
        tree-sitter-javascript
        tree-sitter-json
        tree-sitter-lua
        tree-sitter-ruby
        tree-sitter-scss
        tree-sitter-sql
        tree-sitter-tsx
        tree-sitter-typescript
        tree-sitter-xml
        tree-sitter-yaml
      ]
    );
  };

  # telescope-fzf-native is a C library. Under lazy.nvim it carries
  # `build = "make"`, which needs a compiler at runtime and silently leaves the
  # extension broken when there isn't one — the same failure mode the
  # treesitter grammars above were moved into Nix to avoid.
  #
  # nixpkgs already ships it compiled, so it is linked to a stable path below
  # and lua/plugins/telescope.lua points lazy's `dir` at that path. lazy then
  # treats it as a local plugin: no clone, no build step, no lock entry.
  fzfNative = pkgs.vimPlugins.telescope-fzf-native-nvim;
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    withNodeJs = true; # required by a few plugins' node hosts
    withPython3 = false;
    withRuby = false;

    # `withNodeJs` makes the nixpkgs wrapper emit provider config, which HM
    # would otherwise write to ~/.config/nvim/init.lua — colliding with the
    # symlinked directory below, and failing the build with "Error installing
    # file '.config/nvim/init.lua' outside $HOME". Sideloading passes that Lua
    # through the wrapper's --cmd instead, leaving our init.lua untouched.
    sideloadInitLua = true;

    # The mason replacement. On nvim's PATH, not the user profile.
    extraPackages = with pkgs; [
      # Lua
      lua-language-server
      stylua

      # Nix
      nil
      alejandra
      statix
      deadnix

      # TypeScript / JavaScript / web
      typescript-language-server
      vscode-langservers-extracted # eslint, html, css, json servers
      prettier
      stylelint

      # Markdown
      markdownlint-cli

      # Plugin runtime deps
      ripgrep # telescope live grep
      fd # telescope file finder
      tree-sitter # :TSInstall for grammars not pinned above
    ];
  };

  # One `xdg` block rather than three `xdg.*` assignments, and `dataFile`
  # written once inside it: statix's repeated-keys lint fires on any leading
  # key that appears more than once in the same attribute set, so the partly
  # nested form still trips it.
  xdg = {
    dataFile = {
      "nvim/site/parser".source = "${treesitterGrammars}/parser";

      # Not under site/: lazy.nvim resets packpath, so nothing here would be
      # sourced automatically anyway — this is only a stable path for lazy's
      # `dir`.
      "nvim/nix/telescope-fzf-native.nvim".source = fzfNative;
    };

    configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink configPath;
  };
}
