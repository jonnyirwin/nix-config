{
  config,
  lib,
	pkgs-unstable,
  ...
}: {
	
  programs.nixvim = {
    enable = true;

    viAlias = true;
    vimAlias = true;

    colorschemes.tokyonight = {
      enable = true;
      transparent = true;
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    options = {
      background = "dark";
      title = true;
      cursorline = true;
      number = true;
      relativenumber = true;
      tabstop = 2;
      softtabstop = 2;
      shiftwidth = 2;
      expandtab = false;
      hlsearch = false;
      incsearch = true;
      autoindent = true;
      undofile = true;
      wrap = false;
      termguicolors = true;
      signcolumn = "yes";
    };

    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };

    plugins = {
      barbar.enable = true;
      comment-nvim.enable = true;
      copilot-vim.enable = true;
      fugitive.enable = true;
      gitsigns.enable = true;
      harpoon.enable = true;
      lsp = {
        enable = true;
        postConfig = ''
          local signs = { Error = "", Warn = "", Hint = "", Information = " " }
          for type, icon in pairs(signs) do
          	local hl = "DiagnosticSign" .. type
          	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
          end
        '';
        keymaps = {
          diagnostic = {
            "<leader>j" = {
              action = "goto_next";
              desc = "Go to next diagnostic";
            };
            "<leader>k" = {
              action = "goto_prev";
              desc = "Go to previous diagnostic";
            };
          };
          lspBuf = {
            K = {
              action = "hover";
              desc = "Show hover";
            };
            gD = {
              action = "references";
              desc = "Show references";
            };
            gd = {
              action = "definition";
              desc = "Show definition";
            };
            gi = {
              action = "implementation";
              desc = "Show implementation";
            };
            gt = {
              action = "type_definition";
              desc = "Show type definition";
            };
            ga = {
              action = "code_action";
              desc = "Show code actions";
            };
            gf = {
              action = "format";
              desc = "Format";
            };
          };
        };
        servers = {
					nil_ls.enable = true;
          tsserver.enable = true;
					hls.enable = true;
					gdscript.enable = true;
        };
      };

      lspkind = {
        enable = true;
        cmp.menu = {
          buffer = "[Buffer]";
          nvim_lsp = "[LSP]";
          luasnip = "[LuaSnip]";
          path = "[Path]";
        };
      };
      lualine.enable = true;
      luasnip.enable = true;

      none-ls = {
        enable = true;
        sources = {
          code_actions.statix.enable = true;
          code_actions.eslint_d.enable = true;
          diagnostics = {
            deadnix.enable = true;
            eslint_d.enable = true;
            statix.enable = true;
          };
          formatting.alejandra.enable = true;
          formatting.prettier.enable = true;
        };
      };

      nvim-cmp = {
        enable = true;
        sources = [
          {name = "nvim_lsp";}
          {name = "luasnip";}
          {name = "buffer";}
          {name = "path";}
        ];
        formatting.fields = ["kind" "abbr" "menu"];
        mappingPresets = ["insert"];
        mapping = {
          "<C-j>" = "cmp.mapping.select_next_item()";
          "<C-k>" = "cmp.mapping.select_prev_item()";
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
        };
        window.completion = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None";
          colOffset = -4;
          sidePadding = 0;
          border = "single";
        };
        window.documentation = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None";
          border = "single";
        };
        snippet.expand = "luasnip";
      };

      cmp-buffer.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp_luasnip.enable = true;

      surround.enable = true;
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = {
            action = "find_files";
            desc = "Telescope Find Files";
          };
          "<leader>fg" = {
            action = "live_grep";
            desc = "Telescope Live Grep";
          };
          "<leader>fb" = {
            action = "buffers";
            desc = "Telescope Buffers";
          };
          "<leader>fh" = {
            action = "help_tags";
            desc = "Telescope Help Tags";
          };
        };
        extensions.fzf-native.enable = true;
      };
      tmux-navigator.enable = true;
      treesitter.enable = true;
      treesitter-textobjects.enable = true;
      trouble.enable = true;
      undotree.enable = true;

      which-key.enable = true;
      nvim-tree.enable = true;
    };

    keymaps = let
      normal =
        lib.mapAttrsToList
        (key: action: {
          mode = "n";
          inherit action key;
        })
        {
          "<Space>" = "<NOP>";
          "<C-d>" = "<C-d>zz";
          "<C-u>" = "<C-u>zz";
          "n" = "nzzzv";
          "N" = "Nzzzv";
          "<C-t>" = "";
					"<leader>e" = ":NvimTreeToggle<CR>";
        };
    in
      config.nixvim.helpers.keymaps.mkKeymaps
      {options.silent = true;}
      normal;
  };
}
