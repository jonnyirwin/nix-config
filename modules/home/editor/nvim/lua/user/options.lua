-- General Neovim settings


local opt = vim.opt
opt.number = true
opt.relativenumber = true

opt.tabstop = 2       -- Width of tab character
opt.softtabstop = 2   -- Number of spaces inserted when hitting Tab
opt.shiftwidth = 2    -- Width of indents
opt.expandtab = false -- Use tabs instead of spaces
opt.smarttab = true   -- Be smart about using tabs
opt.autoindent = true
opt.smartindent = true

opt.wrap = false

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

opt.cursorline = true

opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

opt.splitright = true
opt.splitbelow = true

opt.iskeyword:append("-")

opt.updatetime = 100

-- Performance optimizations
opt.timeoutlen = 300  -- Faster which-key response
opt.ttimeoutlen = 10  -- Faster escape sequence timeout

opt.swapfile = false
opt.backup = false

opt.undofile = true

opt.scrolloff = 8

opt.clipboard = 'unnamedplus'

-- Auto-reload files when changed externally
opt.autoread = true

-- Autocmd to trigger autoread when switching to Neovim or moving cursor
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  command = "checktime",
  desc = "Check if file needs to be reloaded from disk"
})
