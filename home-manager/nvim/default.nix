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
			lsp.enable = true;
			lspkind.enable = true;
			lualine.enable = true;
			luasnip.enable = true;
			nvim-cmp.enable = true;
			surround.enable = true;
			telescope.enable = true;
			tmux-navigator.enable = true;
			treesitter.enable = true;
			treesitter-textobjects.enable = true;
			undotree.enable = true;
			which-key.enable =true;
		};
	};
}
