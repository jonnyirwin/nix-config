return {
    "kevinhwang91/nvim-ufo",
    dependencies = {
        "kevinhwang91/promise-async",
        "nvim-treesitter/nvim-treesitter",
    },
    event = "BufReadPost",
    config = function()
        vim.o.foldcolumn = 'auto:9'
        vim.o.foldlevel = 99
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true
        
        -- Set fold column icons to triangles
        vim.opt.fillchars = {
            foldopen = "▼",
            foldclose = "►", 
            fold = " ",
            foldsep = " ",
            diff = "╱",
            eob = " ",
        }

        -- Use treesitter and LSP for folding
        require('ufo').setup({
            provider_selector = function(bufnr, filetype, buftype)
                return { 'treesitter', 'indent' }
            end,
            -- Fold preview
            preview = {
                win_config = {
                    border = { '', '─', '', '', '', '─', '', '' },
                    winhighlight = 'Normal:Folded',
                    winblend = 0,
                },
                mappings = {
                    scrollU = '<C-u>',
                    scrollD = '<C-d>',
                    jumpTop = '[',
                    jumpBot = ']',
                },
            },
            -- Fold text customization - remove numbers from virtual text
            fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = ' 󰁂 '  -- Just the icon without the number count
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        local hlGroup = chunk[2]
                        table.insert(newVirtText, { chunkText, hlGroup })
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, 'MoreMsg' })
                return newVirtText
            end,
        })

        -- Folding keybindings
        vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
        vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
        vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds, { desc = 'Open folds except kinds' })
        vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith, { desc = 'Close folds with' })
        vim.keymap.set('n', 'zp', function()
            local winid = require('ufo').peekFoldedLinesUnderCursor()
            if not winid then
                vim.lsp.buf.hover()
            end
        end, { desc = 'Peek fold or hover' })

        -- Additional useful fold keybindings
        vim.keymap.set('n', 'zO', 'zCzO', { desc = 'Close other folds, open current' })
        vim.keymap.set('n', '[z', '[zzz', { desc = 'Go to previous fold and center' })
        vim.keymap.set('n', ']z', ']zzz', { desc = 'Go to next fold and center' })
    end,
}
