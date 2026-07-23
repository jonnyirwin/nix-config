return {
    "smoka7/multicursors.nvim",
    dependencies = {
        'nvimtools/hydra.nvim',
    },
    opts = {},
    cmd = { 'MCstart', 'MCvisual', 'MCclear', 'MCpattern', 'MCvisualPattern', 'MCunderCursor' },
    keys = {
        {
            mode = { 'v', 'n' },
            '<Leader>M',
            '<cmd>MCstart<cr>',
            desc = 'Create a selection for selected text or word under the cursor',
        },
        {
            mode = { 'v', 'n' },
            '<Leader>Mv',
            '<cmd>MCvisual<cr>',
            desc = 'Create multiple cursors in visual mode',
        },
        {
            mode = { 'v', 'n' },
            '<Leader>Mp',
            '<cmd>MCpattern<cr>',
            desc = 'Create selections by pattern search',
        },
        {
            mode = { 'n' },
            '<Leader>Mu',
            '<cmd>MCunderCursor<cr>',
            desc = 'Create selections under cursor',
        },
    },
}
