return {
    {
        "nvim-neotest/neotest",
        keys = {
            { "<leader>tf" }, { "<leader>tn" }, { "<leader>ts" },
            { "<leader>tl" }, { "<leader>tv" }, { "<leader>tS" }, { "<leader>to" },
        },
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            "olimorris/neotest-rspec", -- RSpec adapter for neotest
            "jfpedroza/neotest-elixir", -- ExUnit adapter for neotest
        },
        config = function()
            require("neotest").setup({
                adapters = {
                    require("neotest-rspec")({
                        rspec_cmd = function()
                            -- Prefer bin/rspec if available; otherwise bundle exec rspec
                            if vim.uv.fs_stat("bin/rspec") then
                                return { "bin/rspec" }
                            end
                            return { "bundle", "exec", "rspec" }
                        end,
                        transform_spec_path = function(path)
                            return path
                        end,
                        results_path = "tmp/rspec.output"
                    }),
                    require("neotest-elixir")({
                        -- ExUnit configuration
                        mix_task = "test", -- Mix task for running tests (default: test)
                        post_process_command = function(cmd)
                            -- Add any post-processing for the mix test command
                            return cmd
                        end,
                    }),
                },
                discovery = {
                    enabled = false,
                },
                running = {
                    concurrent = true,
                },
                summary = {
                    enabled = true,
                    expand_errors = true,
                },
                output = {
                    enabled = true,
                    open_on_run = "short",
                },
                quickfix = {
                    enabled = false,
                },
            })

            -- Neotest keybindings (these will replace the vim-rspec ones)
            vim.keymap.set("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Test file" })
            vim.keymap.set("n", "<leader>tn", function() require("neotest").run.run() end, { desc = "Test nearest" })
            vim.keymap.set("n", "<leader>ts", function() require("neotest").run.run(vim.fn.getcwd()) end, { desc = "Test suite" })
            vim.keymap.set("n", "<leader>tl", function() require("neotest").run.run_last() end, { desc = "Test last" })
            vim.keymap.set("n", "<leader>tv", function() require("neotest").output_panel.toggle() end, { desc = "Test output panel" })
            vim.keymap.set("n", "<leader>tS", function() require("neotest").summary.toggle() end, { desc = "Test summary" })
            vim.keymap.set("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end, { desc = "Test output" })
        end,
    },
}
