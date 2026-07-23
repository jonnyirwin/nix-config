return {
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>ma" }, { "<leader>mh" },
            { "<leader>1" }, { "<leader>2" }, { "<leader>3" }, { "<leader>4" },
            { "<C-S-P>" }, { "<C-S-N>" },
        },
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()

            -- Harpoon keybindings for quick Rails file navigation
            vim.keymap.set("n", "<leader>ma", function() harpoon:list():add() end, { desc = "Add file to harpoon" })
            vim.keymap.set("n", "<leader>mh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Show harpoon menu" })

            vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Jump to harpoon file 1" })
            vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Jump to harpoon file 2" })
            vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Jump to harpoon file 3" })
            vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Jump to harpoon file 4" })

            -- Toggle previous & next buffers stored within Harpoon list
            vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
            vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)
        end,
    },
    {
        -- Enhanced Rails file navigation
        "tpope/vim-projectionist",
        init = function()
            -- Add Rails-specific projectionist patterns
            vim.g.projectionist_heuristics = {
                ["Gemfile&config/application.rb"] = {
                    ["app/models/*.rb"] = {
                        type = "model",
                        alternate = "spec/models/{}_spec.rb",
                        template = {
                            "class {camelcase|capitalize|colons}",
                            "end"
                        }
                    },
                    ["app/controllers/*_controller.rb"] = {
                        type = "controller",
                        alternate = "spec/controllers/{}_controller_spec.rb",
                        template = {
                            "class {camelcase|capitalize|colons}Controller < ApplicationController",
                            "end"
                        }
                    },
                    ["app/views/*.html.erb"] = {
                        type = "view",
                        alternate = "spec/views/{}_spec.rb"
                    },
                    ["spec/models/*_spec.rb"] = {
                        type = "spec",
                        alternate = "app/models/{}.rb",
                        template = {
                            "require 'rails_helper'",
                            "",
                            "RSpec.describe {camelcase|capitalize|colons}, type: :model do",
                            "  pending \"add some examples to (or delete) #{__FILE__}\"",
                            "end"
                        }
                    },
                    ["spec/controllers/*_controller_spec.rb"] = {
                        type = "spec",
                        alternate = "app/controllers/{}_controller.rb",
                        template = {
                            "require 'rails_helper'",
                            "",
                            "RSpec.describe {camelcase|capitalize|colons}Controller, type: :controller do",
                            "  pending \"add some examples to (or delete) #{__FILE__}\"",
                            "end"
                        }
                    }
                }
            }
        end,
    },
}
