return {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false,
    opts = {},
    config = function(_, opts)
        require('oil').setup(opts)
        vim.keymap.set("n", "<leader>e", "<CMD>Oil --float<CR>", { desc = "Open Oil" })
    end,
}
