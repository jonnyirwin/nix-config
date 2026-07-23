vim.bo.expandtab = true
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2

vim.bo.textwidth = 120
vim.wo.colorcolumn = "120"

-- HAML-specific settings
vim.bo.filetype = "haml"

-- Enable automatic indentation for HAML
vim.bo.autoindent = true
vim.bo.smartindent = true

-- HAML uses significant whitespace, so we want to be careful with trailing spaces
vim.opt_local.list = true
vim.opt_local.listchars = { trail = '·', tab = '→ ' }

-- HAML-specific keybindings for Rails development
local keymap = vim.keymap
keymap.set("n", "<leader>rv", ":A<CR>", { desc = "Rails alternate file (controller/view toggle)", buffer = true })
keymap.set("n", "<leader>rC", ":Econtroller<CR>", { desc = "Go to controller", buffer = true })
