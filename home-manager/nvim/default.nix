{ config, lib, ... }:
{
	programs.nixvim = {
		enable = true;

		viAlias = true;
		vimAlias = true;

		colorschemes.tokyonight.enable = true;
	
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
		};

		plugins = {
			barbar.enable = true;
			comment-nvim.enable = true;
			fugitive.enable = true;
			gitsigns.enable = true;
			harpoon.enable = true;

			lsp = {
				enable = true;
				servers = {
					nixd.enable = true;
				};
			};

			lspkind.enable = true;
			lualine.enable = true;
			luasnip.enable = true;

			nvim-cmp = {
				enable = true;
				sources = [
					{ name = "nvim_lsp"; }
					{ name = "luasnip"; }
					{ name = "buffer"; }
					{ name = "path";  }
				];
				formatting.fields = [ "kind" "abbr" "menu" ];
				mapping = {
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
			telescope.enable = true;
			tmux-navigator.enable = true;
			treesitter.enable = true;
			treesitter-textobjects.enable = true;
			undotree.enable = true;

			which-key.enable = true;
			conform-nvim.enable = true;
			lint.enable = true;
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
		};
		in
			config.nixvim.helpers.keymaps.mkKeymaps
			{ options.silent = true; }
		(normal);
	};
}
