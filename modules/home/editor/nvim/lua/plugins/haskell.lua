return {
    {
        "mrcjkb/haskell-tools.nvim",
        version = "^4",
        ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            local ht = require("haskell-tools")

            -- Ensure ghcup bin directory is in PATH for HLS
            local ghcup_bin = vim.fn.expand("~/.ghcup/bin")
            if vim.fn.isdirectory(ghcup_bin) == 1 then
                vim.env.PATH = ghcup_bin .. ":" .. vim.env.PATH
            end

            -- Configure haskell-tools
            vim.g.haskell_tools = {
                tools = {
                    -- Code lens
                    codeLens = {
                        autoRefresh = true,
                    },
                    -- Hover actions
                    hover = {
                        stylize_markdown = true,
                        auto_focus = false,
                    },
                    -- REPL
                    repl = {
                        handler = "builtin",
                        builtin = {
                            create_repl_window = function(view)
                                return view.create_repl_split({ size = vim.o.lines / 3 })
                            end,
                        },
                    },
                },
                hls = {
                    -- HLS (Haskell Language Server) configuration
                    on_attach = function(client, bufnr)
                        -- Ensure semantic tokens don't override treesitter italics
                        vim.api.nvim_set_hl(0, '@lsp.type.keyword.haskell', { italic = true })
                        vim.api.nvim_set_hl(0, '@lsp.type.parameter.haskell', { italic = true })
                        vim.api.nvim_set_hl(0, '@lsp.type.typeParameter.haskell', { italic = true })
                        vim.api.nvim_set_hl(0, '@lsp.type.variable.haskell', { italic = true })
                        vim.api.nvim_set_hl(0, '@lsp.mod.readonly.haskell', { italic = true })

                        local bufopts = { noremap = true, silent = true, buffer = bufnr }

                        -- Haskell-specific LSP keybindings using <leader>h namespace
                        vim.keymap.set("n", "<leader>hf", vim.lsp.buf.format, bufopts)
                        vim.keymap.set("n", "<leader>hs", ht.hoogle.hoogle_signature, { desc = "Haskell: Hoogle signature" })
                        vim.keymap.set(
                            "n",
                            "<leader>he",
                            ht.lsp.buf_eval_all,
                            { buffer = bufnr, desc = "Haskell: Evaluate all" }
                        )

                        -- REPL integration
                        vim.keymap.set("n", "<leader>hr", function()
                            ht.repl.toggle(vim.api.nvim_buf_get_name(0))
                        end, { desc = "Haskell: Toggle REPL for current file" })

                        vim.keymap.set("n", "<leader>hR", function()
                            ht.repl.toggle()
                        end, { desc = "Haskell: Toggle REPL for current package" })

                        vim.keymap.set("n", "<leader>hq", ht.repl.quit, { desc = "Haskell: Quit REPL" })

                        -- Project management
                        vim.keymap.set(
                            "n",
                            "<leader>hp",
                            ht.project.open_package_yaml,
                            { desc = "Haskell: Open package.yaml" }
                        )
                        vim.keymap.set(
                            "n",
                            "<leader>hc",
                            ht.project.open_package_cabal,
                            { desc = "Haskell: Open cabal file" }
                        )
                    end,
                    default_settings = {
                        haskell = {
                            formattingProvider = "fourmolu", -- or 'ormolu', 'stylish-haskell', 'brittany'
                            checkProject = true,
                            maxCompletions = 40,
                            plugin = {
                                -- Enable/disable specific HLS plugins
                                alternateNumberFormat = { globalOn = true },
                                callHierarchy = { globalOn = true },
                                changeTypeSignature = { globalOn = true },
                                class = { globalOn = true },
                                eval = { globalOn = true },
                                excplicitFixity = { globalOn = true },
                                gadt = { globalOn = true },
                                -- HLint integration for linting
                                hlint = {
                                    globalOn = true,
                                    diagnosticsOn = true,
                                    codeActionsOn = true,
                                },
                                importLens = {
                                    globalOn = true,
                                    codeActionsOn = true,
                                    codeLensOn = true,
                                },
                                moduleName = { globalOn = true },
                                pragmas = {
                                    codeActionsOn = true,
                                    completionOn = true,
                                },
                                qualifyImportedNames = { globalOn = true },
                                refineImports = {
                                    globalOn = true,
                                    codeActionsOn = true,
                                    codeLensOn = true,
                                },
                                rename = {
                                    globalOn = true,
                                    config = {
                                        crossModule = true,
                                    },
                                },
                                retrie = { globalOn = true },
                                semanticTokens = { globalOn = true },
                                splice = { globalOn = true },
                                tactics = {
                                    globalOn = true,
                                    config = {
                                        auto_gas = 4,
                                        timeout_duration = 2,
                                    },
                                },
                            },
                        },
                    },
                },
            }

            -- Additional Haskell keybindings (non-LSP)
            vim.keymap.set("n", "<leader>hH", function()
                ht.hoogle.hoogle_signature()
            end, { desc = "Haskell: Search Hoogle" })

            -- Debug command to check HLS status
            vim.api.nvim_create_user_command("HaskellLspStatus", function()
                local clients = vim.lsp.get_clients({ name = "hls" })
                if #clients == 0 then
                    print("Haskell Language Server not running")
                    return
                end

                local client = clients[1]
                local root_dir = client.config.root_dir or vim.fn.getcwd()

                print("Haskell Language Server is running:")
                print("  - Root dir: " .. root_dir)
                print("  - Formatter: " .. (vim.g.haskell_tools.hls.default_settings.haskell.formattingProvider or "auto"))
                print("  - HLint enabled: " .. (vim.g.haskell_tools.hls.default_settings.haskell.plugin.hlint.globalOn and "✓" or "✗"))
                print("  - Project checking: " .. (vim.g.haskell_tools.hls.default_settings.haskell.checkProject and "✓" or "✗"))
            end, { desc = "Show Haskell LSP status" })
        end,
    },
}
