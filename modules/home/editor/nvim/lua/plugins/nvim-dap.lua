return {
    "rcarriga/nvim-dap-ui",
    keys = {
        { "<leader>db" }, { "<leader>dB" }, { "<leader>dc" }, { "<leader>ds" },
        { "<leader>di" }, { "<leader>do" }, { "<leader>dr" }, { "<leader>dl" },
        { "<leader>dt" }, { "<leader>du" }, { "<leader>de" },
        { "<leader>rd" }, { "<leader>id" }, { "<leader>iD" }, { "<leader>iP" },
    },
    dependencies = {
        "nvim-neotest/nvim-nio",
        "mfussenegger/nvim-dap",
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        -- Setup DAP UI
        dapui.setup({
            icons = { expanded = "▾", collapsed = "▸" },
            mappings = {
                expand = { "<CR>", "<2-LeftMouse>" },
                open = "o",
                remove = "d",
                edit = "e",
                repl = "r",
                toggle = "t",
            },
            layouts = {
                {
                    elements = {
                        { id = "scopes", size = 0.25 },
                        "breakpoints",
                        "stacks",
                        "watches",
                    },
                    size = 40,
                    position = "left",
                },
                {
                    elements = {
                        "repl",
                        "console",
                    },
                    size = 0.25,
                    position = "bottom",
                },
            },
            floating = {
                max_height = nil,
                max_width = nil,
                border = "single",
                mappings = {
                    close = { "q", "<Esc>" },
                },
            },
            windows = { indent = 1 },
            render = {
                max_type_length = nil,
            }
        })

        -- Ruby: attach-only to a running rdbg session.
        -- Start server with: bundle exec rdbg -n --open --host 127.0.0.1 --port 38698 -c -- bin/rails server
        dap.adapters.ruby = {
            type = "server",
            host = "127.0.0.1",
            port = 38698,
        }

        dap.configurations.ruby = {
            {
                type = "ruby",
                request = "attach",
                name = "Attach to rdbg (127.0.0.1:38698)",
            },
        }

        -- Elixir DAP configuration
        -- Elixir debugging with IEx
        dap.adapters.mix_task = {
            type = "executable",
            command = "elixir",
            args = { "-S", "mix", "test", "--trace" },
        }

        dap.configurations.elixir = {
            {
                type = "mix_task",
                name = "mix test",
                task = "test",
                taskArgs = { "--trace" },
                request = "launch",
                startApps = true, -- for Phoenix projects
                projectDir = "${workspaceFolder}",
                requireFiles = {
                    "test/**/test_helper.exs",
                    "test/**/*_test.exs"
                }
            },
            {
                type = "mix_task", 
                name = "mix test (current file)",
                task = "test",
                taskArgs = { "${file}", "--trace" },
                request = "launch",
                startApps = true,
                projectDir = "${workspaceFolder}",
                requireFiles = {
                    "test/**/test_helper.exs",
                    "${file}"
                }
            },
            {
                type = "mix_task",
                name = "Phoenix Server Debug",
                task = "phx.server",
                request = "launch",
                startApps = true,
                projectDir = "${workspaceFolder}",
                requireFiles = {}
            }
        }
        
        -- Customize DAP signs to look like VSCode
        vim.fn.sign_define('DapBreakpoint', {
            text = '●',           -- Solid circle
            texthl = 'DapBreakpoint',
            linehl = '',
            numhl = ''
        })
        
        vim.fn.sign_define('DapBreakpointCondition', {
            text = '◐',           -- Half circle for conditional breakpoints
            texthl = 'DapBreakpointCondition',
            linehl = '',
            numhl = ''
        })
        
        vim.fn.sign_define('DapLogPoint', {
            text = '◆',           -- Diamond for log points
            texthl = 'DapLogPoint',
            linehl = '',
            numhl = ''
        })
        
        vim.fn.sign_define('DapStopped', {
            text = '▶',           -- Arrow for current execution point
            texthl = 'DapStopped',
            linehl = 'DapStoppedLine',
            numhl = ''
        })
        
        vim.fn.sign_define('DapBreakpointRejected', {
            text = '○',           -- Empty circle for rejected breakpoints
            texthl = 'DapBreakpointRejected',
            linehl = '',
            numhl = ''
        })

        -- Set up highlight groups with Catppuccin theme colors
        local function set_dap_colors()
          -- Get Catppuccin colors if available
          local has_catppuccin, catppuccin = pcall(require, "catppuccin.palettes")
          local colors = has_catppuccin and catppuccin.get_palette() or {}
          
          -- Fallback to default colors if Catppuccin not available
          local red = colors.red or '#e51400'
          local peach = colors.peach or '#f79000'  
          local blue = colors.blue or '#61afef'
          local green = colors.green or '#98c379'
          local surface1 = colors.surface1 or '#2c323c'
          local overlay0 = colors.overlay0 or '#5c6370'
          
          vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = red })           -- Red for breakpoints
          vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { fg = peach }) -- Orange for conditional
          vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = blue })            -- Blue for log points
          vim.api.nvim_set_hl(0, 'DapStopped', { fg = green })            -- Green for current line
          vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = surface1 })     -- Theme background
          vim.api.nvim_set_hl(0, 'DapBreakpointRejected', { fg = overlay0 }) -- Gray for rejected
        end
        
        -- Set colors immediately and after colorscheme changes
        set_dap_colors()
        vim.api.nvim_create_autocmd("ColorScheme", {
          callback = set_dap_colors,
          desc = "Update DAP colors when colorscheme changes"
        })

        -- Auto open/close DAP UI
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end

        -- DAP keybindings
        vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
        vim.keymap.set("n", "<leader>dB", function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, { desc = "Set Conditional Breakpoint" })
        vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Start/Continue" })
        vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
        vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
        vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
        vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
        vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })
        vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })
        
        -- DAP UI keybindings
        vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle Debug UI" })
        vim.keymap.set("n", "<leader>de", dapui.eval, { desc = "Evaluate Expression" })
        vim.keymap.set("v", "<leader>de", dapui.eval, { desc = "Evaluate Selection" })

        -- Ruby: attach to running rdbg
        vim.keymap.set("n", "<leader>rd", function()
            dap.run(dap.configurations.ruby[1])
        end, { desc = "Attach to rdbg" })

        -- Elixir/Phoenix specific debugging keybindings
        vim.keymap.set("n", "<leader>id", function()
            -- Debug nearest ExUnit test
            local configs = dap.configurations.elixir
            if configs then
                for _, config in ipairs(configs) do
                    if config.name and config.name:match("current.*file") then
                        dap.run(config)
                        return
                    end
                end
            end
            -- Fallback if configuration not found
            print("ExUnit test debugging configuration not found")
        end, { desc = "Debug nearest ExUnit test" })

        vim.keymap.set("n", "<leader>iD", function()
            -- Debug all ExUnit tests
            local configs = dap.configurations.elixir
            if configs then
                for _, config in ipairs(configs) do
                    if config.name and config.name:match("mix test") and not config.name:match("current") then
                        dap.run(config)
                        return
                    end
                end
            end
            -- Fallback if configuration not found
            print("ExUnit full test debugging configuration not found")
        end, { desc = "Debug all ExUnit tests" })

        vim.keymap.set("n", "<leader>iP", function()
            -- Debug Phoenix server
            local configs = dap.configurations.elixir
            if configs then
                for _, config in ipairs(configs) do
                    if config.name and config.name:match("Phoenix.*Server") then
                        dap.run(config)
                        return
                    end
                end
            end
            -- Fallback if configuration not found
            print("Phoenix server debugging configuration not found")
        end, { desc = "Debug Phoenix server" })
    end,
}
