assert(vim.api.nvim_ui_send, "chameleon.nvim requires Neovim 0.12 or later")
vim.g.colors_name = "chameleon"

require("chameleon.terminal")(function(colors)
	local palette = require("chameleon.palette")(colors)
	-- Setting 'background' can reload the active colorscheme.
	vim.g.colors_name = nil
	vim.o.background = palette.mode
	vim.o.termguicolors = true
	vim.cmd("hi clear")
	vim.g.colors_name = "chameleon"
	for group, spec in pairs(require("chameleon.highlighter")(palette)) do
		vim.api.nvim_set_hl(0, group, spec)
	end
	for i = 0, 15 do
		vim.g["terminal_color_" .. i] = colors[i]
	end
	vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "chameleon", modeline = false })
end)
