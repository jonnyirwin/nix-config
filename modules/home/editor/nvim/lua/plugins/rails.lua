return { 
    {
        'tpope/vim-rails',
        ft = { 'ruby', 'eruby', 'haml', 'slim' },
        cmd = { 'Rails', 'Rake', 'Rextract', 'Rinvert', 'A', 'R', 'Emodel', 'Emigration', 'Eschema', 'Econtroller', 'Eview', 'Ehelper', 'Eroutes', 'Ejob', 'Emailer' },
        config = function()
            -- Ensure Rails detection runs
            vim.cmd([[
                if filereadable('Gemfile') || filereadable('config/application.rb')
                    let g:rails_detect_open = 1
                    silent! call rails#buffer_setup()
                endif
            ]])
            
            -- === PRIMARY RAILS NAVIGATION ===
            vim.keymap.set('n', '<leader>rv', function()
                pcall(vim.cmd, 'A')
            end, { desc = 'Rails: alternate file (test ↔ implementation)' })
            
            vim.keymap.set('n', '<leader>rm', function()
                pcall(vim.cmd, 'Emodel')
            end, { desc = 'Rails: edit model' })
            
            vim.keymap.set('n', '<leader>rg', function()
                pcall(vim.cmd, 'Emigration')
            end, { desc = 'Rails: edit migration' })
            
            vim.keymap.set('n', '<leader>rV', function()
                pcall(vim.cmd, 'Rails routes')
            end, { desc = 'Rails: show routes table' })
            
            vim.keymap.set('n', '<leader>rS', function()
                pcall(vim.cmd, 'Eschema')
            end, { desc = 'Rails: edit schema' })
            
            vim.keymap.set('n', '<leader>rt', function()
                pcall(vim.cmd, 'Rake')
            end, { desc = 'Rails: run Rake task' })
            
            -- === SECONDARY RAILS NAVIGATION ===
            vim.keymap.set('n', '<leader>rr', function()
                pcall(vim.cmd, 'R')
            end, { desc = 'Rails: related file navigation' })
            
            -- === ADDITIONAL RAILS COMMANDS ===
            vim.keymap.set('n', '<leader>rec', function()
                pcall(vim.cmd, 'Econtroller')
            end, { desc = 'Rails: edit controller' })
            
            vim.keymap.set('n', '<leader>rev', function()
                pcall(vim.cmd, 'Eview')
            end, { desc = 'Rails: edit view' })
            
            vim.keymap.set('n', '<leader>reh', function()
                pcall(vim.cmd, 'Ehelper')
            end, { desc = 'Rails: edit helper' })
            
            vim.keymap.set('n', '<leader>rer', function()
                pcall(vim.cmd, 'Eroutes')
            end, { desc = 'Rails: edit routes.rb' })
            
            vim.keymap.set('n', '<leader>rej', function()
                pcall(vim.cmd, 'Ejob')
            end, { desc = 'Rails: edit job' })
            
            vim.keymap.set('n', '<leader>rem', function()
                pcall(vim.cmd, 'Emailer')
            end, { desc = 'Rails: edit mailer' })
            
            -- Debug command to check Rails commands availability
            vim.keymap.set('n', '<leader>rD', function()
                local commands = { 'Rails', 'A', 'R', 'Emodel', 'Emigration', 'Eschema', 'Econtroller', 'Eview' }
                for _, cmd in ipairs(commands) do
                    local exists = vim.fn.exists(':' .. cmd) > 0
                    print(cmd .. ": " .. (exists and "Available" or "NOT AVAILABLE"))
                end
                print("Rails project: " .. (vim.fn.filereadable('Gemfile') == 1 and "Yes" or "No"))
                print("Current buffer: " .. vim.bo.filetype)
            end, { desc = 'Rails: debug commands availability' })
        end,
    },
    { 'tpope/vim-bundler' },
    { 'tpope/vim-haml' },
    { 'tpope/vim-endwise' },
    { 'tpope/vim-rake', dependencies = { 'tpope/vim-projectionist' } },
    { 'tpope/vim-dispatch' },
    { 'thoughtbot/vim-rspec',
        config = function()
            vim.g.rspec_command = "Dispatch rspec {spec}"
        end
    },
}