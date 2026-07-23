-- Accent hex: read from ~/.config/catppuccin/accent.hex (single source across dotfiles).
local function read_accent_hex()
    local f = vim.fn.expand('~/.config/catppuccin/accent.hex')
    if vim.fn.filereadable(f) == 1 then
        return '#' .. vim.trim(vim.fn.readfile(f)[1] or 'cba6f7')
    end
    return '#cba6f7'
end
local accent = read_accent_hex()

return {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    opts = {
        workspaces = {
            {
                name = "Second-Brain",
                path = "~/git/Second-Brain",
            },
        },

        daily_notes = {
            folder = "A - Inbox",
            date_format = "%Y-%m-%d",
            template = "(Template) - Daily Note.md",
        },

        completion = {
            nvim_cmp = false,
            min_chars = 2,
        },

        new_notes_location = "notes_subdir",
        notes_subdir = "A - Inbox",
        templates = {
            folder = "D - Templates",
            date_format = "%Y-%m-%d",
            time_format = "%H:%M",
        },

        wiki_link_func = function(opts)
            return require("obsidian.util").wiki_link_id_prefix(opts)
        end,

        note_id_func = function(title)
            local suffix = ""
            if title ~= nil then
                suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
            else
                for _ = 1, 4 do
                    suffix = suffix .. string.char(math.random(65, 90))
                end
            end
            return tostring(os.time()) .. "-" .. suffix
        end,

        follow_url_func = function(url)
            vim.fn.jobstart({ "xdg-open", url })
        end,

        use_advanced_uri = false,
        open_app_foreground = false,

        picker = {
            name = "telescope.nvim",
        },

        sort_by = "modified",
        sort_reversed = true,

        ui = {
            enable = true,
            update_debounce = 200,
            checkboxes = {
                [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
                ["x"] = { char = "", hl_group = "ObsidianDone" },
                [">"] = { char = "", hl_group = "ObsidianRightArrow" },
                ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
            },
            bullets = { char = "•", hl_group = "ObsidianBullet" },
            external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
            reference_text = { hl_group = "ObsidianRefText" },
            highlight_text = { hl_group = "ObsidianHighlightText" },
            tags_text = { hl_group = "ObsidianTag" },
            hl_groups = {
                ObsidianTodo = { bold = true, fg = "#f38ba8" },
                ObsidianDone = { bold = true, fg = "#a6e3a1" },
                ObsidianRightArrow = { bold = true, fg = "#fab387" },
                ObsidianTilde = { bold = true, fg = "#f38ba8" },
                ObsidianBullet = { bold = true, fg = "#89b4fa" },
                ObsidianRefText = { underline = true, fg = accent },
                ObsidianExtLinkIcon = { fg = accent },
                ObsidianTag = { italic = true, fg = "#89b4fa" },
                ObsidianHighlightText = { bg = "#45475a" },
            },
        },

        mappings = {
            ["gf"] = {
                action = function()
                    return require("obsidian").util.gf_passthrough()
                end,
                opts = { noremap = false, expr = true, buffer = true },
            },
            ["<cr>"] = {
                action = function()
                    return require("obsidian").util.smart_action()
                end,
                opts = { buffer = true, expr = true },
            },
        },
    },

    config = function(_, opts)
        require("obsidian").setup(opts)

        local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { desc = desc })
        end

        map("<leader>on", "<cmd>ObsidianNew<cr>", "New note")
        map("<leader>oo", "<cmd>ObsidianOpen<cr>", "Open in Obsidian app")
        map("<leader>of", "<cmd>ObsidianQuickSwitch<cr>", "Find note")
        map("<leader>og", "<cmd>ObsidianSearch<cr>", "Grep notes")
        map("<leader>od", "<cmd>ObsidianToday<cr>", "Today's daily note")
        map("<leader>oD", "<cmd>ObsidianDailies<cr>", "Browse daily notes")
        map("<leader>ob", "<cmd>ObsidianBacklinks<cr>", "Backlinks")
        map("<leader>ol", "<cmd>ObsidianLinks<cr>", "Links in note")
        map("<leader>oi", "<cmd>ObsidianPasteImg<cr>", "Paste image")
        map("<leader>ot", "<cmd>ObsidianTags<cr>", "Browse tags")
        map("<leader>oT", "<cmd>ObsidianTemplate<cr>", "Insert template")
        map("<leader>or", "<cmd>ObsidianRename<cr>", "Rename note")
        map("<leader>oc", "<cmd>ObsidianToggleCheckbox<cr>", "Toggle checkbox")

        vim.keymap.set("v", "<leader>ol", function()
            vim.cmd("ObsidianLink")
        end, { desc = "Link selection to note" })

        vim.keymap.set("v", "<leader>on", function()
            vim.cmd("ObsidianLinkNew")
        end, { desc = "Link selection to new note" })
    end,
}
