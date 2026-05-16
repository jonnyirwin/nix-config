-- ============================================================
-- Additional LSP configurations for Nix-provided servers
-- ============================================================
--
-- This file is NOT automatically sourced. It shows you what to
-- ADD to ~/.dotfiles/neovim/.config/nvim/lua/plugins/lsp.lua
-- to wire up the LSP servers now available via your Nix config.
--
-- Copy the relevant blocks into your lsp.lua config() function,
-- after the existing vim.lsp.config(...) calls.
-- ============================================================

-- ============================================================
-- Rust (rust-analyzer)
-- ============================================================
-- rust-analyzer is installed by modules/dev/rust.nix.
-- It provides: completion, go-to-definition, inlay hints,
-- cargo integration, proc-macro expansion, and more.
--
-- Add to lsp.lua config() function:

vim.lsp.config('rust_analyzer', {
    capabilities = capabilities,
    settings = {
        ['rust-analyzer'] = {
            -- Run clippy (the linter) instead of just cargo check.
            -- Clippy catches more issues at the cost of slightly slower analysis.
            checkOnSave = {
                command = "clippy",
                -- Pass extra clippy args if needed:
                -- extraArgs = { "--", "-W", "clippy::all" },
            },
            -- Inlay hints show types, parameter names, etc. inline.
            -- Toggle with your <leader>lH binding (already in lsp.lua).
            inlayHints = {
                parameterHints = { enable = true },
                typeHints      = { enable = true },
                chainingHints  = { enable = true },
            },
            -- Expand proc macros (show what macros expand to).
            procMacro = { enable = true },
            -- cargo features to enable during analysis.
            cargo = {
                allFeatures = true,
                -- loadOutDirsFromCheck = true,  -- needed for some build.rs patterns
            },
            -- Assist settings: which code actions to show.
            assist = {
                importGranularity = "module",    -- group imports by module
                importPrefix      = "self",       -- use `self::` prefix for local imports
            },
        },
    },
})
vim.lsp.enable('rust_analyzer')

-- ============================================================
-- Nix — FULL LSP + LINTING + FORMATTING STACK
-- ============================================================
--
-- Tools installed by modules/editor.nix:
--   nil        → LSP server (completion, go-to-def, hover, refs)
--   alejandra  → formatter (already in your none-ls.lua!)
--   statix     → static analyser / linter (nil_ls runs it automatically)
--   deadnix    → dead code finder (nil_ls runs it automatically)
--
-- Your none-ls.lua ALREADY has alejandra for formatting:
--   null_ls.builtins.formatting.alejandra
-- So formatting is handled. The below wires up the LSP for completion,
-- navigation, and the statix/deadnix diagnostics.
--
-- Add to lsp.lua config() function:

vim.lsp.config('nil_ls', {
    capabilities = capabilities,
    settings = {
        ['nil'] = {
            formatting = {
                -- Delegate formatting to alejandra (already on PATH via nix).
                -- This makes `=` in normal mode and <leader>lf use alejandra.
                command = { "alejandra" },
            },
            nix = {
                -- nil_ls runs statix and deadnix automatically when they're on
                -- PATH (installed via editor.nix). Diagnostics appear inline.
                --
                -- To disable flake check diagnostics (can be slow on big flakes):
                -- flake = { autoArchive = false },
            },
        },
    },
})
vim.lsp.enable('nil_ls')

-- ============================================================
-- none-ls additions for Nix (ADD to your none-ls.lua sources table)
-- ============================================================
--
-- Your none-ls.lua already has alejandra. These add explicit statix
-- diagnostics as a null-ls source (in addition to what nil_ls shows):
--
-- In none-ls.lua, add to the sources = { ... } table:
--
--   -- statix: lint Nix expressions for common mistakes and anti-patterns
--   null_ls.builtins.diagnostics.statix,
--
--   -- deadnix: find unused variables and function arguments in Nix files
--   null_ls.builtins.diagnostics.deadnix,
--
-- Note: nil_ls already surfaces statix/deadnix findings as LSP diagnostics,
-- so adding them to none-ls too will DUPLICATE those warnings. Choose one:
--   a) LSP only (nil_ls) — simpler, no duplication
--   b) none-ls only (disable statix in nil_ls settings) — more control
--   c) Both — more warnings visible in :Trouble / quickfix, but duplicated
-- Recommendation: let nil_ls handle it (option a).
-- ============================================================

-- ============================================================
-- Haskell (hls — already handled by haskell-tools.nvim)
-- ============================================================
-- Your existing lua/plugins/haskell.lua uses haskell-tools.nvim
-- which manages HLS directly. Do NOT add hls here — doing so would
-- start two competing HLS clients for the same buffer.
--
-- If you switch away from haskell-tools.nvim, you'd add:
--
-- vim.lsp.config('hls', {
--     capabilities = capabilities,
--     filetypes = { 'haskell', 'lhaskell', 'cabal' },
--     rootPatterns = { '*.cabal', 'stack.yaml', 'cabal.project', 'package.yaml', 'hie.yaml' },
-- })
-- vim.lsp.enable('hls')

-- ============================================================
-- Lua (lua_ls — for editing your own Neovim config)
-- ============================================================
-- lua-language-server is installed by modules/editor.nix.
-- Add to lsp.lua config() function:

vim.lsp.config('lua_ls', {
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = {
                -- Neovim embeds LuaJIT.
                version = "LuaJIT",
            },
            workspace = {
                -- Make lua_ls aware of Neovim's runtime files so it can
                -- complete vim.*, require("..."), etc. without false errors.
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,  -- suppress "Do you need to configure..." prompts
            },
            diagnostics = {
                -- Recognise the `vim` global (stops "undefined global 'vim'" warnings).
                globals = { "vim" },
            },
            telemetry = { enable = false },
        },
    },
})
vim.lsp.enable('lua_ls')
