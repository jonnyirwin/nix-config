return {
    "nvimtools/none-ls.nvim",
    event = "BufReadPost",
    dependencies = {
        "nvim-lua/plenary.nvim"
    },
    config = function()
        local null_ls = require("null-ls")
        local h = require("null-ls.helpers")
        local u = require("null-ls.utils")
        
        -- Custom haml_lint source using helpers
        local haml_lint = h.make_builtin({
            name = "haml_lint",
            meta = {
                url = "https://github.com/sds/haml-lint",
                description = "Tool for writing clean and consistent HAML",
            },
            method = null_ls.methods.DIAGNOSTICS,
            filetypes = { "haml" },
            generator_opts = {
                command = "bundle",
                args = { "exec", "haml-lint", "--reporter", "json", "$FILENAME" },
                to_stdin = false,
                from_stderr = false,
                format = "json",
                check_exit_code = function(code)
                    return code <= 65
                end,
                on_output = function(params)
                    local diagnostics = {}
                    if params.output and params.output.files then
                        for _, file in ipairs(params.output.files) do
                            if file.offenses then
                                for _, offense in ipairs(file.offenses) do
                                    table.insert(diagnostics, {
                                        row = offense.location.line,
                                        col = offense.location.column or 1,
                                        message = offense.message,
                                        severity = offense.severity == "error" and h.diagnostics.severities.error or h.diagnostics.severities.warning,
                                        source = "haml_lint",
                                    })
                                end
                            end
                        end
                    end
                    return diagnostics
                end,
            },
            factory = h.generator_factory,
        })
        
        null_ls.setup({
            sources = {
                null_ls.builtins.code_actions.gitsigns,
                null_ls.builtins.completion.luasnip,
                haml_lint.with({
                    cwd = h.cache.by_bufnr(function(params)
                        return u.root_pattern("Gemfile")(params.bufname)
                    end),
                }),
                null_ls.builtins.diagnostics.markdownlint,
                null_ls.builtins.diagnostics.stylelint,
                
                -- Elixir formatting and linting
                null_ls.builtins.formatting.mix.with({
                    cwd = h.cache.by_bufnr(function(params)
                        return u.root_pattern("mix.exs")(params.bufname)
                    end),
                }),
                
                null_ls.builtins.formatting.alejandra,
                null_ls.builtins.formatting.markdownlint,
                null_ls.builtins.formatting.prettier,
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.formatting.erb_lint.with({
                    command = "bundle",
                    prepend_args = { "exec", "erb_lint" },
                    cwd = h.cache.by_bufnr(function(params)
                        return u.root_pattern("Gemfile")(params.bufname)
                    end),
                }),
            },
        })
    end,
}