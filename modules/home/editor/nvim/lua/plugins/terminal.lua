return {
    {
        'akinsho/toggleterm.nvim',
        version = "*",
        keys = {
            { "<c-\\>" },
            { "<leader>xf" }, { "<leader>xh" }, { "<leader>xv" },
            { "<leader>rc" }, { "<leader>rs" },
            { "<leader>ixc" }, { "<leader>ixs" }, { "<leader>ixt" }, { "<leader>ixl" },
        },
        config = function()
            require("toggleterm").setup({
                size = 20,
                open_mapping = [[<c-\>]],
                hide_numbers = true,
                shade_filetypes = {},
                shade_terminals = true,
                shading_factor = 2,
                start_in_insert = true,
                insert_mappings = true,
                persist_size = true,
                direction = "float",
                close_on_exit = true,
                shell = vim.o.shell,
                float_opts = {
                    border = "curved",
                    winblend = 0,
                    highlights = {
                        border = "Normal",
                        background = "Normal",
                    },
                },
            })

            -- Terminal keybindings
            local Terminal = require('toggleterm.terminal').Terminal

            -- Rails console terminal
            local rails_console = Terminal:new({
                cmd = "rails console",
                dir = "git_dir",
                direction = "float",
                float_opts = {
                    border = "double",
                },
                on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
                on_close = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            -- Rails server terminal
            local rails_server = Terminal:new({
                cmd = "rails server",
                dir = "git_dir",
                direction = "horizontal",
                on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
                on_close = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            -- Phoenix/Elixir terminals
            local iex_console = Terminal:new({
                cmd = "iex -S mix",
                dir = "git_dir",
                direction = "horizontal",
                on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
                on_close = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            local phoenix_server = Terminal:new({
                cmd = "mix phx.server",
                dir = "git_dir", 
                direction = "horizontal",
                on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
                on_close = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            local mix_test = Terminal:new({
                cmd = "mix test --stale",
                dir = "git_dir",
                direction = "horizontal", 
                close_on_exit = false,
                on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
                on_close = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            local livebook = Terminal:new({
                cmd = "livebook server",
                dir = "git_dir",
                direction = "horizontal",
                on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
                on_close = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            -- Functions to toggle terminals
            function _rails_console_toggle()
                rails_console:toggle()
            end

            function _rails_server_toggle()
                rails_server:toggle()
            end

            -- Elixir/Phoenix terminal functions
            function _iex_console_toggle()
                iex_console:toggle()
            end

            function _phoenix_server_toggle()
                phoenix_server:toggle()
            end

            function _mix_test_toggle()
                mix_test:toggle()
            end

            function _livebook_toggle()
                livebook:toggle()
            end

            -- Terminal keybindings
            vim.keymap.set("n", "<leader>xf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Float terminal" })
            vim.keymap.set("n", "<leader>xh", "<cmd>ToggleTerm size=10 direction=horizontal<cr>", { desc = "Horizontal terminal" })
            vim.keymap.set("n", "<leader>xv", "<cmd>ToggleTerm size=80 direction=vertical<cr>", { desc = "Vertical terminal" })
            
            -- Rails terminals
            vim.keymap.set("n", "<leader>rc", "<cmd>lua _rails_console_toggle()<CR>", { desc = "Rails console" })
            vim.keymap.set("n", "<leader>rs", "<cmd>lua _rails_server_toggle()<CR>", { desc = "Rails server" })
            
            -- Elixir/Phoenix terminals (using ix for terminal/eXecution commands)
            vim.keymap.set("n", "<leader>ixc", "<cmd>lua _iex_console_toggle()<CR>", { desc = "IEx console" })
            vim.keymap.set("n", "<leader>ixs", "<cmd>lua _phoenix_server_toggle()<CR>", { desc = "Phoenix server" })
            vim.keymap.set("n", "<leader>ixt", "<cmd>lua _mix_test_toggle()<CR>", { desc = "Mix test (stale)" })
            vim.keymap.set("n", "<leader>ixl", "<cmd>lua _livebook_toggle()<CR>", { desc = "LiveBook server" })

            -- Terminal mode keybindings
            vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
            vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], { desc = "Navigate left" })
            vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], { desc = "Navigate down" })
            vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], { desc = "Navigate up" })
            vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], { desc = "Navigate right" })
        end,
    },
}
