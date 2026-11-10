local send
local term_program
local notify
local list_uis
local cursorline

---Simulate terminal responses for a palette.
---@param colors table
local function respond(colors)
	for index = 0, 15 do
		local color = colors[index]
		vim.api.nvim_exec_autocmds("TermResponse", {
			data = {
				sequence = string.format(
					"\027]4;%d;rgb:%s/%s/%s",
					index,
					color:sub(2, 3),
					color:sub(4, 5),
					color:sub(6, 7)
				),
			},
		})
	end
	for index, key in ipairs({ "foreground", "background" }) do
		local color = colors[key]
		vim.api.nvim_exec_autocmds("TermResponse", {
			data = {
				sequence = string.format(
					"\027]%d;rgb:%s/%s/%s",
					index + 9,
					color:sub(2, 3),
					color:sub(4, 5),
					color:sub(6, 7)
				),
			},
		})
	end
end

return {
	---Save editor state and prepare terminal mocks.
	before = function()
		require("chameleon.terminal").cancel()
		require("chameleon.terminal").colors = nil
		cursorline = vim.opt.cursorline:get()
		vim.opt.cursorline = false
		term_program = vim.env.TERM_PROGRAM
		send = vim.api.nvim_ui_send
		---Suppress terminal queries during the test.
		vim.api.nvim_ui_send = function() end
		notify = vim.notify
		---Suppress notifications during the test.
		vim.notify = function() end
		list_uis = vim.api.nvim_list_uis
		---Simulate the attached terminal UI state.
		vim.api.nvim_list_uis = function()
			return { { stdout_tty = true } }
		end
	end,

	---Cancel pending queries and restore editor state.
	after = function()
		require("chameleon.terminal").cancel()
		vim.api.nvim_ui_send = send
		vim.api.nvim_list_uis = list_uis
		vim.env.TERM_PROGRAM = term_program
		vim.notify = notify
		vim.opt.cursorline = cursorline
	end,

	---Verify: Loading the colorscheme enables the cursor line and allows a user override.
	["Loading the colorscheme enables the cursor line and allows a user override"] = function()
		-- When
		vim.cmd.colorscheme("chameleon")
		respond(require("tests.current.colors"))

		-- Then
		assert(vim.wo.cursorline, "Cursor line was not enabled")

		-- When
		vim.opt.cursorline = false
		respond(require("tests.current.colors"))

		-- Then
		assert(not vim.wo.cursorline, "User override was reset")
	end,

	---Verify: Terminal theme colors are applied as Neovim highlights.
	["Terminal theme colors are applied as Neovim highlights"] = function()
		-- When
		vim.cmd.colorscheme("chameleon")
		respond(require("tests.current.colors"))

		-- Then
		local got = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Normal" }).fg)
		local want = "#d2dbdc"
		assert(got == want, "got:" .. got .. ",want:" .. want)
		assert(vim.g.colors_name == "chameleon")
		assert(vim.o.termguicolors)
		assert(vim.g.terminal_color_1 == "#dd7a72")
	end,

	---Verify: Terminal theme colors are applied outside of Rex.
	["Terminal theme colors are applied outside of Rex"] = function()
		-- Given
		vim.env.TERM_PROGRAM = "another-terminal"
		vim.api.nvim_set_hl(0, "Normal", { fg = "#ffffff" })

		-- When
		vim.cmd.colorscheme("chameleon")
		respond(require("tests.current.colors"))

		-- Then
		assert(vim.api.nvim_get_hl(0, { name = "Normal" }).fg == 0xd2dbdc)
		assert(vim.g.colors_name == "chameleon")
	end,

	---Verify: Previous highlights set by other themes are cleared.
	["Previous highlights set by other themes are cleared"] = function()
		-- Given
		vim.api.nvim_set_hl(0, "HighlightGroupToClear", { fg = "#ffffff" })

		-- When
		vim.cmd.colorscheme("chameleon")
		respond(require("tests.current.colors"))

		-- Then
		assert(vim.api.nvim_get_hl(0, { name = "HighlightGroupToClear" }).fg == nil, "Highlights were not cleared")
	end,

	---Verify: Light terminal palettes set the Neovim background to light.
	["Light terminal palettes set the Neovim background to light"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.background = "#ffffff"
		colors.foreground = "#222222"

		-- When
		vim.cmd.colorscheme("chameleon")
		respond(colors)

		-- Then
		assert(vim.o.background == "light")
		assert(vim.api.nvim_get_hl(0, { name = "Normal" }).bg == 0xffffff)
		assert(vim.api.nvim_get_hl(0, { name = "PmenuSel" }).fg == 0x222222)
	end,

	---Verify: Switching colorscheme cancels the palette query and ignores late responses.
	["Switching colorscheme cancels the palette query and ignores late responses"] = function()
		-- Given
		vim.cmd.colorscheme("chameleon")
		vim.cmd.colorscheme("default")
		local previous = vim.api.nvim_get_hl(0, { name = "Normal" })

		-- When
		respond(require("tests.current.colors"))

		-- Then
		assert(vim.g.colors_name == "default")
		assert(vim.deep_equal(vim.api.nvim_get_hl(0, { name = "Normal" }), previous))
		assert(#vim.api.nvim_get_autocmds({ group = "chameleon-query" }) == 0)
	end,

	---Verify: Palette changes are only read when the colorscheme is loaded again.
	["Palette changes are only read when the colorscheme is loaded again"] = function()
		-- Given
		vim.cmd.colorscheme("chameleon")
		respond(require("tests.current.colors"))
		local updated = vim.deepcopy(require("tests.current.colors"))
		updated.foreground = "#ffffff"

		-- When
		respond(updated)

		-- Then
		assert(vim.api.nvim_get_hl(0, { name = "Normal" }).fg == 0xd2dbdc)
		assert(#vim.api.nvim_get_autocmds({ group = "chameleon-query" }) == 0, "Palette listeners were left running")

		-- When
		vim.cmd.colorscheme("chameleon")
		respond(updated)

		-- Then
		assert(vim.api.nvim_get_hl(0, { name = "Normal" }).fg == 0xffffff)
	end,

	---Verify: Colorscheme loaded before the TUI attaches waits for UIEnter.
	["Colorscheme loaded before the TUI attaches waits for UIEnter"] = function()
		-- Given
		---Simulate the attached terminal UI state.
		vim.api.nvim_list_uis = function()
			return {}
		end
		local queries = 0
		---Record terminal queries sent by the plugin.
		vim.api.nvim_ui_send = function()
			queries = queries + 1
		end

		-- When
		vim.cmd.colorscheme("chameleon")

		-- Then
		assert(queries == 0, "Queried before the TUI attached")

		-- When
		vim.api.nvim_exec_autocmds("UIEnter", {})
		assert(
			---Check whether the asynchronous operation has completed.
			vim.wait(500, function()
				return queries == 1
			end),
			"Palette query was not sent after UIEnter"
		)
		respond(require("tests.current.colors"))

		-- Then
		assert(queries == 1)
		assert(vim.api.nvim_get_hl(0, { name = "Normal" }).fg == 0xd2dbdc)
	end,
}
