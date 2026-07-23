return {
    "catppuccin/nvim",
    name = "catppuccin",
		priority = 1000,
    lazy = false,
    config = function()
      require('catppuccin').setup({
				styles = {
					comments = { "italic" },
					conditionals = { "italic" },
					loops = { "italic" },
					functions = {},
					keywords = { "italic" },
					strings = {},
					variables = {},
					numbers = {},
					booleans = {},
					properties = {},
					types = {},
					operators = {},
				},
        integrations = {
          barbar = true,
          dadbod_ui = true,
					lsp_trouble = true,
        }
      })

      vim.cmd("colorscheme catppuccin")
			vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
			vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
			vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'none' })
			vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'none' })
			vim.api.nvim_set_hl(0, 'Terminal', { bg = 'none' })
			vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = 'none' })
			vim.api.nvim_set_hl(0, 'FoldColumn', { bg = 'none' })
			vim.api.nvim_set_hl(0, 'Folded', { bg = 'none' })
			vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'none' })

			-- Helper function to add italic while preserving existing colors
			local function add_italic(group_name)
				local hl = vim.api.nvim_get_hl(0, { name = group_name, link = false })
				if next(hl) ~= nil then
					hl.italic = true
					vim.api.nvim_set_hl(0, group_name, hl)
				end
			end

			-- Italic styling
			add_italic('Comment')

			-- Keywords (general)
			add_italic('@keyword')
			add_italic('@keyword.conditional')
			add_italic('@keyword.repeat')
			add_italic('@keyword.return')
			add_italic('@keyword.function')
			add_italic('@keyword.operator')
			add_italic('@keyword.import')
			add_italic('@keyword.modifier')
			add_italic('@keyword.storage')

			-- Parameters and variables
			add_italic('@parameter')
			add_italic('@variable.builtin')
			add_italic('@variable.parameter')

			-- Types
			add_italic('@type.builtin')
			add_italic('@type.qualifier')

			-- LSP semantic tokens (for HLS)
			add_italic('@lsp.type.keyword')
			add_italic('@lsp.type.parameter')
			add_italic('@lsp.type.typeParameter')
			add_italic('@lsp.type.modifier')
    end
  }
