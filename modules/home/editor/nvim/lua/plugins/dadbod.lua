return {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
        { 'tpope/vim-dadbod', lazy = true },
        { 
            'kristijanhusak/vim-dadbod-completion', 
            ft = { 'sql', 'mysql', 'plsql', 'postgresql', 'sqlite' },
        },
    },
    cmd = {
        'DBUI',
        'DBUIToggle',
        'DBUIAddConnection',
        'DBUIFindBuffer',
    },
    init = function()
        -- Basic DBUI configuration
        vim.g.db_ui_use_nerd_fonts = 1
        vim.g.db_ui_auto_execute_table_helpers = 1
        vim.g.db_ui_show_database_icon = 1
        vim.g.db_ui_win_position = 'left'
        vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
        
        -- Minimal tree collapse prevention
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "dbui",
            callback = function()
                vim.opt_local.foldmethod = "manual"
                vim.opt_local.foldenable = false
            end,
        })
        
        -- Enhanced Rails database auto-detection
        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
                local cwd = vim.fn.getcwd()
                local db_config = cwd .. '/config/database.yml'
                
                -- Only proceed if database.yml exists
                if vim.fn.filereadable(db_config) == 0 then
                    return
                end
                
                -- Verify this is actually a Rails project
                local is_rails_project = vim.fn.filereadable(cwd .. '/Gemfile') == 1 or
                                                                vim.fn.filereadable(cwd .. '/config/application.rb') == 1 or
                                                                vim.fn.isdirectory(cwd .. '/app') == 1
                
                if not is_rails_project then
                    return
                end
                
                local connections = {}
                
                -- Check environment variables first (for production-like setups)
                local database_url = os.getenv('DATABASE_URL')
                if database_url then
                    connections['Rails (DATABASE_URL)'] = database_url
                end
                
                -- Check for SQLite files (common in development)
                local sqlite_paths = {
                    cwd .. '/storage/development.sqlite3',
                    cwd .. '/db/development.sqlite3',
                    cwd .. '/tmp/development.sqlite3'
                }
                
                for _, path in ipairs(sqlite_paths) do
                    if vim.fn.filereadable(path) == 1 then
                        connections['Rails Development'] = 'sqlite:' .. path
                        break
                    end
                end
                
                local test_sqlite_paths = {
                    cwd .. '/storage/test.sqlite3',
                    cwd .. '/db/test.sqlite3',
                    cwd .. '/tmp/test.sqlite3'
                }
                
                for _, path in ipairs(test_sqlite_paths) do
                    if vim.fn.filereadable(path) == 1 then
                        connections['Rails Test'] = 'sqlite:' .. path
                        break
                    end
                end
                
                -- Enhanced PostgreSQL/MySQL detection from database.yml
                if vim.fn.filereadable(db_config) == 1 then
                    local content = vim.fn.readfile(db_config)
                    local current_env = nil
                    local dev_config = {}
                    local test_config = {}
                    
                    for _, line in ipairs(content) do
                        -- Detect environment sections
                        if line:match('^development:') then
                            current_env = 'development'
                        elseif line:match('^test:') then
                            current_env = 'test'
                        elseif line:match('^production:') then
                            current_env = 'production'
                        elseif line:match('^%w+:') then
                            current_env = nil
                        end
                        
                        -- Parse configuration within environments
                        if current_env == 'development' then
                            local adapter = line:match('%s+adapter:%s*(%S+)')
                            local database = line:match('%s+database:%s*(%S+)')
                            local host = line:match('%s+host:%s*(%S+)')
                            local port = line:match('%s+port:%s*(%S+)')
                            local username = line:match('%s+username:%s*(%S+)')
                            local password = line:match('%s+password:%s*(%S+)')
                            
                            if adapter then dev_config.adapter = adapter end
                            if database then dev_config.database = database end
                            if host then dev_config.host = host end
                            if port then dev_config.port = port end
                            if username then dev_config.username = username end
                            if password then dev_config.password = password end
                            
                        elseif current_env == 'test' then
                            local adapter = line:match('%s+adapter:%s*(%S+)')
                            local database = line:match('%s+database:%s*(%S+)')
                            local host = line:match('%s+host:%s*(%S+)')
                            local port = line:match('%s+port:%s*(%S+)')
                            local username = line:match('%s+username:%s*(%S+)')
                            local password = line:match('%s+password:%s*(%S+)')
                            
                            if adapter then test_config.adapter = adapter end
                            if database then test_config.database = database end
                            if host then test_config.host = host end
                            if port then test_config.port = port end
                            if username then test_config.username = username end
                            if password then test_config.password = password end
                        end
                    end
                    
                    -- Build connection strings for development
                    if dev_config.adapter and dev_config.database then
                        local conn_str = nil
                        if dev_config.adapter == 'postgresql' then
                            local host = dev_config.host or 'localhost'
                            local port = dev_config.port or '5432'
                            local user_pass = ''
                            if dev_config.username then
                                user_pass = dev_config.username
                                if dev_config.password then
                                    user_pass = user_pass .. ':' .. dev_config.password
                                end
                                user_pass = user_pass .. '@'
                            end
                            conn_str = 'postgresql://' .. user_pass .. host .. ':' .. port .. '/' .. dev_config.database
                        elseif dev_config.adapter == 'mysql2' or dev_config.adapter == 'mysql' then
                            local host = dev_config.host or 'localhost'
                            local port = dev_config.port or '3306'
                            local user_pass = ''
                            if dev_config.username then
                                user_pass = dev_config.username
                                if dev_config.password then
                                    user_pass = user_pass .. ':' .. dev_config.password
                                end
                                user_pass = user_pass .. '@'
                            end
                            conn_str = 'mysql://' .. user_pass .. host .. ':' .. port .. '/' .. dev_config.database
                        elseif dev_config.adapter == 'sqlite3' then
                            -- Handle SQLite with custom path from database.yml
                            conn_str = 'sqlite:' .. cwd .. '/' .. dev_config.database
                        end
                        
                        if conn_str and not connections['Rails Development'] then
                            connections['Rails Development'] = conn_str
                        end
                    end
                    
                    -- Build connection strings for test
                    if test_config.adapter and test_config.database then
                        local conn_str = nil
                        if test_config.adapter == 'postgresql' then
                            local host = test_config.host or 'localhost'
                            local port = test_config.port or '5432'
                            local user_pass = ''
                            if test_config.username then
                                user_pass = test_config.username
                                if test_config.password then
                                    user_pass = user_pass .. ':' .. test_config.password
                                end
                                user_pass = user_pass .. '@'
                            end
                            conn_str = 'postgresql://' .. user_pass .. host .. ':' .. port .. '/' .. test_config.database
                        elseif test_config.adapter == 'mysql2' or test_config.adapter == 'mysql' then
                            local host = test_config.host or 'localhost'
                            local port = test_config.port or '3306'
                            local user_pass = ''
                            if test_config.username then
                                user_pass = test_config.username
                                if test_config.password then
                                    user_pass = user_pass .. ':' .. test_config.password
                                end
                                user_pass = user_pass .. '@'
                            end
                            conn_str = 'mysql://' .. user_pass .. host .. ':' .. port .. '/' .. test_config.database
                        elseif test_config.adapter == 'sqlite3' then
                            -- Handle SQLite with custom path from database.yml
                            conn_str = 'sqlite:' .. cwd .. '/' .. test_config.database
                        end
                        
                        if conn_str and not connections['Rails Test'] then
                            connections['Rails Test'] = conn_str
                        end
                    end
                end
                
                -- Only set connections if we found any and this is definitely a Rails project
                if not vim.tbl_isempty(connections) then
                    vim.g.dbs = connections
                    -- Notify user about auto-detected connections
                    local count = 0
                    for _ in pairs(connections) do count = count + 1 end
                    vim.notify('🗄️ Auto-detected ' .. count .. ' Rails database connection(s)', vim.log.levels.INFO)
                end
            end,
        })
        
        -- Minimal tree collapse prevention
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "dbui",
            callback = function()
                vim.opt_local.foldmethod = "manual"
                vim.opt_local.foldenable = false
            end,
        })
        
        -- Save cursor position when leaving DBUI
        vim.api.nvim_create_autocmd("BufLeave", {
            pattern = "*",
            callback = function()
                if vim.bo.filetype == "dbui" then
                    local cursor_pos = vim.api.nvim_win_get_cursor(0)
                    vim.b.dbui_cursor_pos = cursor_pos
                end
            end,
        })
        
        -- Restore cursor position when entering DBUI
        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "*",
            callback = function()
                if vim.bo.filetype == "dbui" and vim.b.dbui_cursor_pos then
                    vim.api.nvim_win_set_cursor(0, vim.b.dbui_cursor_pos)
                end
            end,
        })
    end,
}