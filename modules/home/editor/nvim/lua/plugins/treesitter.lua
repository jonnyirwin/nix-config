return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        -- Grammars are supplied prebuilt by Nix — see the
        -- nvim-treesitter.withPlugins list in modules/home/editor/neovim.nix.
        -- The old runtime install (`build = ":TSUpdate"` plus an
        -- ensure_installed loop) compiled 24 grammars on first launch and
        -- needed a C toolchain present; keep the two lists in sync instead.
        config = function()
            vim.api.nvim_create_autocmd('FileType', {
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require("nvim-treesitter-textobjects").setup {
                select = { lookahead = true },
                move = { set_jumps = true },
            }

            local sel = require("nvim-treesitter-textobjects.select")
            local select_maps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
                ["al"] = "@loop.outer",
                ["il"] = "@loop.inner",
                ["aa"] = "@parameter.outer",
                ["ia"] = "@parameter.inner",
                ["ab"] = "@block.outer",
                ["ib"] = "@block.inner",
                ["ar"] = "@return.outer",
                ["ir"] = "@return.inner",
                ["as"] = "@statement.outer",
                ["is"] = "@statement.inner",
                ["ad"] = "@conditional.outer",
                ["id"] = "@conditional.inner",
            }
            for key, query in pairs(select_maps) do
                vim.keymap.set({ "x", "o" }, key, function()
                    sel.select_textobject(query, "textobjects")
                end)
            end

            local mov = require("nvim-treesitter-textobjects.move")
            local move_maps = {
                next_start  = { ["]m"] = "@function.outer", ["]]"] = "@class.outer", ["]l"] = "@loop.outer", ["]a"] = "@parameter.outer", ["]d"] = "@conditional.outer" },
                next_end    = { ["]M"] = "@function.outer", ["]["] = "@class.outer", ["]L"] = "@loop.outer", ["]A"] = "@parameter.outer", ["]D"] = "@conditional.outer" },
                prev_start  = { ["[m"] = "@function.outer", ["[["] = "@class.outer", ["[l"] = "@loop.outer", ["[a"] = "@parameter.outer", ["[d"] = "@conditional.outer" },
                prev_end    = { ["[M"] = "@function.outer", ["[]"] = "@class.outer", ["[L"] = "@loop.outer", ["[A"] = "@parameter.outer", ["[D"] = "@conditional.outer" },
            }
            for key, query in pairs(move_maps.next_start) do
                vim.keymap.set({ "n", "x", "o" }, key, function() mov.goto_next_start(query, "textobjects") end)
            end
            for key, query in pairs(move_maps.next_end) do
                vim.keymap.set({ "n", "x", "o" }, key, function() mov.goto_next_end(query, "textobjects") end)
            end
            for key, query in pairs(move_maps.prev_start) do
                vim.keymap.set({ "n", "x", "o" }, key, function() mov.goto_previous_start(query, "textobjects") end)
            end
            for key, query in pairs(move_maps.prev_end) do
                vim.keymap.set({ "n", "x", "o" }, key, function() mov.goto_previous_end(query, "textobjects") end)
            end

            local swap = require("nvim-treesitter-textobjects.swap")
            vim.keymap.set("n", "<leader>na", function() swap.swap_next("@parameter.inner") end)
            vim.keymap.set("n", "<leader>nf", function() swap.swap_next("@function.outer") end)
            vim.keymap.set("n", "<leader>pa", function() swap.swap_previous("@parameter.inner") end)
            vim.keymap.set("n", "<leader>pf", function() swap.swap_previous("@function.outer") end)
        end,
    },
}
