local M = {}

M.name = "chameleon"

---@param colors table
local function apply_colors(colors)
	if vim.g.colors_name ~= M.name then
		return
	end

	local palette = require("chameleon.palette").palette_for(colors)
	local highlights = require("chameleon.highlighter").highlights_for(palette)

	-- Changing 'background' can reload the active colorscheme. Set it before registering ours.
	vim.g.colors_name = nil
	vim.o.background = palette.mode
	vim.o.termguicolors = true
	vim.cmd.hi("clear")
	vim.g.colors_name = M.name

	-- Apply highlight groups
	for group, hl in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, hl)
	end

	for index = 0, 15 do
		vim.g["terminal_color_" .. index] = colors[index]
	end
end

function M.apply()
	if not vim.api.nvim_ui_send then
		vim.notify("chameleon.nvim requires Neovim 0.12 or later.", vim.log.levels.ERROR)
		return
	end

	local terminal = require("chameleon.terminal")
	terminal.cancel()
	vim.g.colors_name = M.name
	vim.opt.cursorline = true
	local colors = terminal.colors
	if colors then
		apply_colors(colors)
	end
	terminal.query(function(result)
		if vim.g.colors_name ~= M.name then
			return
		end
		apply_colors(result)
		-- Notify plugins after the asynchronous palette has been applied.
		vim.api.nvim_exec_autocmds("ColorScheme", { pattern = M.name, modeline = false })
	end)
end

return M
