vim.diagnostic.config({ virtual_text = true })

vim.bo.expandtab = true
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2

-- Custom Tab mapping to insert spaces when completion isn't active
local function smart_tab()
	-- Check if blink.cmp completion menu is visible
	local blink_ok, blink = pcall(require, 'blink.cmp')
	if blink_ok then
		local status = blink.is_visible()
		if status then
			return blink.accept()
		end
	end

	-- Otherwise, insert spaces
	return vim.api.nvim_replace_termcodes('<Tab>', true, true, true)
end

vim.keymap.set('i', '<Tab>', smart_tab, { buffer = true, expr = true, noremap = true })
