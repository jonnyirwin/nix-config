return {
    'goolord/alpha-nvim',
    event = 'VimEnter',
    opts = function() 
        local dashboard = require'alpha.themes.dashboard'
        local logo = [[
        ██╗   ██╗██╗███████╗██╗   ██╗ █████╗ ██╗         ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗ 
        ██║   ██║██║██╔════╝██║   ██║██╔══██╗██║         ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗
        ██║   ██║██║███████╗██║   ██║███████║██║         ███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║
        ╚██╗ ██╔╝██║╚════██║██║   ██║██╔══██║██║         ╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║
         ╚████╔╝ ██║███████║╚██████╔╝██║  ██║███████╗    ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝
          ╚═══╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝ 
        ]]
        
        -- Add a custom info line
        local info_line = "󰃰 " .. os.date("%A, %B %d") .. "  " .. vim.fn.getcwd():gsub(os.getenv("HOME"), "~")
        
        -- Custom Arnie quotes function
        local arnie_quotes = {
            { "I'll be back." },
            { "Hasta la vista, baby." },
            { "Get to the chopper!" },
            { "It's not a tumor!" },
            { "Come with me if you want to live." },
            { "I need your clothes, your boots and your motorcycle." },
            { "Consider that a divorce." },
            { "What killed the dinosaurs? The Ice Age!" },
            { "If it bleeds, we can kill it." },
            { "You're one ugly motherf... Wait, wrong quote." },
            { "I'm a cybernetic organism, living tissue over metal endoskeleton." },
            { "No problemo." },
            { "Put that cookie down! Now!" },
            { "Who is your daddy and what does he do?" },
            { "It's showtime!" },
            { "Big mistake. Big. Huge." },
            { "Remember, Sully, when I promised to kill you last? I lied." },
            { "Ice to see you." },
            { "Allow me to break the ice." },
            { "What a lovely party. Pity I wasn't invited." }
        }
        
        local function get_arnie_quote()
            math.randomseed(os.time())
            local index = math.random(1, #arnie_quotes)
            return arnie_quotes[index]
        end
        
        dashboard.section.header.val = vim.split(logo, "\n", {})
        
        -- Add info section between header and buttons
        local info_section = {
            type = "text",
            val = info_line,
            opts = {
                hl = "Comment",
                position = "center"
            }
        }
        dashboard.section.buttons.val = {
            dashboard.button("f", "📁 Find file", ":Telescope find_files <CR>"),
            dashboard.button("r", "📄 Recent files", ":Telescope oldfiles <CR>"),
            dashboard.button("t", "🔍 Find text", ":Telescope live_grep <CR>"),
            dashboard.button("c", "⚙️ Config", ":e ~/.config/nvim/init.lua <CR>"),
            dashboard.button("o", "📂 File Manager", ":Oil <CR>"),
            dashboard.button("u", "⬇️ Update", ":Lazy<CR>"),
            dashboard.button("q", "❌ Quit", ":qa<CR>"),
        }           for _, button in ipairs(dashboard.section.buttons.val) do
                button.opts.hl = "AlphaButtons"
                button.opts.hl_shortcut = "AlphaShortcut"
            end

            dashboard.section.header.opts.hl = "AlphaHeader"
            dashboard.section.buttons.opts.hl = "AlphaButtons"
            
            -- Add Arnie quotes footer
            dashboard.section.footer.val = get_arnie_quote()
            dashboard.section.footer.opts.hl = "Type"
            
            -- Create custom layout with info section
            dashboard.config = {
                layout = {
                    { type = "padding", val = 2 },
                    dashboard.section.header,
                    { type = "padding", val = 1 },
                    info_section,
                    { type = "padding", val = 2 },
                    dashboard.section.buttons,
                    { type = "padding", val = 1 },
                    dashboard.section.footer,
                },
                opts = {
                    margin = 5,
                    noautocmd = true
                }
            }
            
            return dashboard
    end,
    config = function (_, dashboard)
        require'alpha'.setup(dashboard.config)
    end
};
