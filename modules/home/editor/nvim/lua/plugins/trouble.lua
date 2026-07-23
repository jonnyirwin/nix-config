return {
    "folke/trouble.nvim",
    opts = {
        -- Configure Trouble to be more stable
        auto_close = false,
        auto_open = false,
        auto_preview = true,
        auto_refresh = true,
        auto_jump = false,
        focus = false,
        restore = true,
        follow = true,
        indent_guides = true,
        max_items = 200,
        multiline = true,
        pinned = false,
        warn_no_results = true,
        open_no_results = false,
        win = {
            type = "split",
            relative = "editor",
            size = 0.3,
            position = "bottom",
        },
        -- Add safer cursor handling
        preview = {
            type = "main",
            scratch = true,
        },
    },
    cmd = "Trouble",
    keys = {
        {
            "<leader>xx",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Diagnostics (Trouble)",
        },
        {
            "<leader>xX",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Buffer Diagnostics (Trouble)",
        },
        {
            "<leader>xs",
            "<cmd>Trouble symbols toggle focus=false<cr>",
            desc = "Symbols (Trouble)",
        },
        {
            "<leader>xl",
            "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
            desc = "LSP Definitions / references / ... (Trouble)",
        },
        {
            "<leader>xL",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Location List (Trouble)",
        },
        {
            "<leader>xQ",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Quickfix List (Trouble)",
        },
    },
}
