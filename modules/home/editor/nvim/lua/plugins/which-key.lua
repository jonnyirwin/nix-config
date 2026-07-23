return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        spec = {
            -- Only define groups, let individual plugins define their own descriptions
            { "<leader>f", group = "Find (Telescope)" },
            { "<leader>l", group = "LSP" },
            { "<leader>b", group = "Buffer" },
            { "<leader>w", group = "Window" },
            { "<leader>g", group = "Git" },
            { "<leader>M", group = "Multi-cursor" },
            { "<leader>a", group = "Tabs" },
            { "<leader>r", group = "Rails/Ruby" },
            { "<leader>re", group = "Rails: errors" },
            { "<leader>i", group = "IEx/Elixir" },
            { "<leader>im", group = "Mix tasks" },
            { "<leader>ie", group = "Elixir: jump" },
            { "<leader>ix", group = "IEx Terminal" },
            { "<leader>m", group = "Motion/Harpoon" },
            { "<leader>d", group = "Debug/Diagnostics" },
            { "<leader>t", group = "Test" },
            { "<leader>x", group = "Terminal" },
            { "<leader>u", group = "UI" },
            { "<leader>h", group = "Haskell" },
            { "<leader>n", group = "Next (Treesitter)" },
            { "<leader>p", group = "Previous (Treesitter)" },
            { "<leader>o", group = "Open/Toggle" },
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
    },
}