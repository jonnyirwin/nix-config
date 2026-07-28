return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    event = "VeryLazy",  -- Load at same time as which-key
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- Prebuilt by Nix (modules/home/editor/neovim.nix) and linked to this
        -- path. `dir` makes lazy use it in place: no clone, no `make`.
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            dir = vim.fn.stdpath('data') .. '/nix/telescope-fzf-native.nvim',
        }
    },
        config = function()
            local telescope = require('telescope')
            local builtin = require('telescope.builtin')    

            telescope.setup {
                defaults = {
                    file_ignore_patterns = { 
                        'node_modules/.*', 
                        '%.git/.*',  -- Only ignore .git directory contents, not .gitignore etc
                        '%.DS_Store',
                        '__pycache__/.*',
                        '%.pyc',
                    },
                    -- Show hidden files by default
                    hidden = true,
                    vimgrep_arguments = {
                        'rg',
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                        '--hidden',  -- Include hidden files in grep
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        -- Follow symbolic links
                        follow = true,
                        -- Show hidden files but respect gitignore for performance
                        find_command = { 'rg', '--files', '--hidden', '--glob', '!.git/*' },
                    },
                    live_grep = {
                        additional_args = function()
                            return { '--hidden', '--glob', '!.git/*' }
                        end,
                    },
                },
            }

            -- Load fzf extension for better performance
            telescope.load_extension('fzf')

            -- Enhanced keybindings for file finding
            vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
            vim.keymap.set('n', '<leader>fa', function()
                builtin.find_files({ 
                    no_ignore = true, 
                    hidden = true,
                })
            end, { desc = 'Find all files (ignore gitignore)' })
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
            vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })
            
            vim.keymap.set('n', '<leader>fd', function()
                builtin.find_files({ cwd = vim.fn.expand('%:p:h') })
            end, { desc = 'Files in current directory' })
            
            -- Diagnostic viewing with Telescope
            vim.keymap.set('n', '<leader>fe', builtin.diagnostics, { desc = 'All diagnostics' })
            vim.keymap.set('n', '<leader>fE', function()
                builtin.diagnostics({ bufnr = 0 })
            end, { desc = 'Current buffer diagnostics' })
            
            -- LSP pickers for additional context
            vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, { desc = 'Document symbols' })
            vim.keymap.set('n', '<leader>fS', builtin.lsp_workspace_symbols, { desc = 'Workspace symbols' })
        end
}
