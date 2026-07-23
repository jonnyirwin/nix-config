return {
	  'saghen/blink.cmp',
    dependencies = {
        { 'rafamadriz/friendly-snippets' },
        { 'L3MON4D3/LuaSnip', version = 'v2.*' },
    },
    version = '1.*',
    opts = {
        snippets = { preset = 'luasnip' },
        keymap = {
            preset = 'default',
            ['<Tab>'] = { 'accept', 'snippet_forward', 'fallback' },
            ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
            ['<CR>'] = { 'accept', 'fallback' },
            ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
            ['<C-e>'] = { 'hide', 'fallback' },
            ['<Esc>'] = { 'hide', 'fallback' },
            ['<C-n>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ['<C-p>'] = { 'select_prev', 'fallback' },
            ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
            ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
        },
        sources = {
            default = { 'lsp', 'path', 'snippets', 'buffer' },
            per_filetype = {
                sql = { 'snippets', 'dadbod', 'buffer' },
                mysql = { 'snippets', 'dadbod', 'buffer' },
                postgresql = { 'snippets', 'dadbod', 'buffer' },
                plsql = { 'snippets', 'dadbod', 'buffer' },
                sqlite = { 'snippets', 'dadbod', 'buffer' },
            },
            providers = {
                dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
            },
        },
        completion = { 
            documentation = { auto_show = true },
            menu = {
                auto_show = true,
                border = 'rounded',
            },
            list = {
                selection = { preselect = true, auto_insert = true },
            },
        },
        signature = { enabled = true },
        fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
    opts_extend = { "sources.default" },
}
