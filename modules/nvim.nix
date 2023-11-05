{
programs.nixvim = {
	enable = true;
	viAlias = true;
	vimAlias = true;

	colorschemes.catppuccin.enable = true;

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

	plugins = 
	{
		lsp = {
			enable = true;
			servers = {
				rnix-lsp = {
					enable = true;
					autostart = true;
				};
				tsserver = {
					enable = true;
					autostart = true;
				};
			};
		};
		nvim-cmp = {
			enable = true;

			sources = [
			{ name = "nvim_lsp" ; }
			];

			mapping = {
				"<C-b>"= "cmp.mapping.scroll_docs(-4)";
				"<C-f>"= "cmp.mapping.scroll_docs(4)";
				"<C-Space>" = "cmp.mapping.complete()";
				"<Tab>" = {
					modes = ["i" "s"];
					action = "cmp.mapping.select_next_item()";
				};
				"<S-Tab>" = {
					modes = ["i" "s"];
					action = "cmp.mapping.select_prev_item()";
				};

				"<C-e>" = "cmp.mapping.abort()";
				"<CR>" = "cmp.mapping.confirm({ select = true })";

			};
		};
		cmp-nvim-lsp.enable = true;
		comment-nvim.enable = true;
		lualine = {
			enable = true;
			theme = "horizon";
		};
		lspkind.enable = true;	
	};
};
}

