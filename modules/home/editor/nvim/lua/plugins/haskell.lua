return {
    {
        "mrcjkb/haskell-tools.nvim",
        version = "^10",
        ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            local ht = require("haskell-tools")

            -- haskell-tools' own `buf_eval_all` assumes every code lens arrives
            -- with a `command` field. HLS sends them unresolved when the client
            -- advertises codeLens resolveSupport (Neovim 0.12 does), so the
            -- plugin errors with "attempt to index field 'command'".
            -- Resolve the lenses here, then run the eval commands bottom-up so
            -- inserted result lines don't shift the ranges still pending.
            local function eval_all(bufnr)
                bufnr = bufnr or vim.api.nvim_get_current_buf()
                local client = vim.lsp.get_clients({ bufnr = bufnr, name = "haskell-tools.nvim" })[1]
                if not client then
                    vim.notify("No haskell-tools LSP client attached.", vim.log.levels.ERROR)
                    return
                end

                local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
                local res = client:request_sync("textDocument/codeLens", params, 10000, bufnr)
                if not res or res.err or not res.result then
                    vim.notify("Could not fetch code lenses from HLS.", vim.log.levels.ERROR)
                    return
                end

                local evals = {}
                for _, lens in ipairs(res.result) do
                    if not lens.command then
                        local resolved = client:request_sync("codeLens/resolve", lens, 10000, bufnr)
                        lens = (resolved and not resolved.err and resolved.result) or lens
                    end
                    if lens.command and lens.command.command:match("evalCommand") then
                        table.insert(evals, lens)
                    end
                end

                if #evals == 0 then
                    vim.notify("No evaluable code snippets found.", vim.log.levels.INFO)
                    return
                end

                table.sort(evals, function(a, b)
                    return a.range.start.line > b.range.start.line
                end)
                for _, lens in ipairs(evals) do
                    client:request_sync("workspace/executeCommand", lens.command, 30000, bufnr)
                end
            end

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
                            function()
                                eval_all(bufnr)
                            end,
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
                                -- Off: throws an internal error on code-action
                                -- requests, and HLS drops it from GHC 9.10 on
                                retrie = { globalOn = false },
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
