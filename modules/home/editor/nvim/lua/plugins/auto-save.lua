return {
    "okuuva/auto-save.nvim",
    cmd = "ASToggle", -- optional for lazy loading on command
    event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
    opts = {
        enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
        trigger_events = { -- vim events that trigger auto-save
            immediate_save = { "BufLeave", "FocusLost" }, -- save immediately on these events
            defer_save = { "InsertLeave", "TextChanged" }, -- save after `debounce_delay` on these events
            cancel_deferred_save = { "InsertEnter" }, -- cancel pending saves on these events
        },
        condition = function(buf)
            local fn = vim.fn

            -- don't save for special-buffers whose 'buftype' is set
            if vim.bo[buf].buftype ~= "" then
                return false
            end

            -- don't save for files in certain directories or with certain extensions
            local ignore_dirs = { "/tmp/", "/.git/", "/node_modules/" }
            local ignore_extensions = { "gitcommit", "gitrebase" }
            
            local filepath = fn.expand("%:p")
            for _, dir in ipairs(ignore_dirs) do
                if string.find(filepath, dir) then
                    return false
                end
            end
            
            local filetype = vim.bo[buf].filetype
            for _, ext in ipairs(ignore_extensions) do
                if filetype == ext then
                    return false
                end
            end
            
            return true
        end,
        write_all_buffers = false, -- write all buffers when the current one meets `condition`
        debounce_delay = 1000, -- saves the file at most every `debounce_delay` milliseconds
        callbacks = { -- functions to run at different events
            enabling = nil,
            disabling = nil,
            before_asserting_save = nil,
            before_saving = nil,
            after_saving = nil
        },
    },
}
