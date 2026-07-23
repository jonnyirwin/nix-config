return {
    'ThePrimeagen/git-worktree.nvim',
    dependencies = {
        'nvim-telescope/telescope.nvim',
        'nvim-lua/plenary.nvim',
    },
    keys = {
        { "<leader>gw", desc = "Switch worktree" },
        { "<leader>gW", desc = "Create worktree" },
    },
    config = function()
        local worktree = require('git-worktree')
        local telescope = require('telescope')

        -- Setup git-worktree
        worktree.setup({
            change_directory_command = 'cd',  -- default: "cd",
            update_on_change = true,  -- default: true,
            update_on_change_command = 'e .',  -- default: "e .",
            clearjumps_on_change = true,  -- default: true,
            autopush = false,  -- default: false,
        })

        -- Load the telescope extension
        telescope.load_extension('git_worktree')

        -- Keymaps for git-worktree operations
        local map = vim.keymap.set

        -- Switch to existing worktree
        map('n', '<leader>gw', function()
            telescope.extensions.git_worktree.git_worktrees()
        end, { desc = 'Switch worktree' })

        -- Create new worktree
        map('n', '<leader>gW', function()
            telescope.extensions.git_worktree.create_git_worktree()
        end, { desc = 'Create worktree' })

        -- Hooks for additional actions on worktree switch
        worktree.on_tree_change(function(op, metadata)
            if op == worktree.Operations.Switch then
                print('Switched to worktree: ' .. metadata.path)
            elseif op == worktree.Operations.Create then
                print('Created worktree: ' .. metadata.path)
            elseif op == worktree.Operations.Delete then
                print('Deleted worktree: ' .. metadata.path)
            end
        end)
    end
}
