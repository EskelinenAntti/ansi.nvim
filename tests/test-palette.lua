return {
	["Terminal ANSI colors are mapped to the same highlight palette as the other themes"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))

		-- When
		local got = require("ansi.palette").palette_for(colors)

		-- Then
		assert(got.background == colors.background)
		assert(got.foreground == colors.foreground)
		assert(got.accent == colors[4])
		assert(got.red == colors[1])
		assert(got.green == colors[2])
		assert(got.orange == colors[3])
		assert(got.bright_cyan == colors[14])
		assert(got.mode == "dark")
		assert(vim.deep_equal(colors, require("tests.current.colors")), "Source colors were modified")
	end,

	["Use ANSI background and foreground when the terminal does not answer OSC 10 and 11"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.background = nil
		colors.foreground = nil

		-- When
		local got = require("ansi.palette").palette_for(colors)

		-- Then
		assert(got.background == colors[0])
		assert(got.foreground == colors[7])
	end,

	["Light themes keep readable foregrounds and derive light surfaces"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.background = "#ffffff"
		colors.foreground = "#000000"

		-- When
		local got = require("ansi.palette").palette_for(colors)

		-- Then
		assert(got.mode == "light")
		assert(got.bright_foreground == "#000000")
		assert(got.selection == "#dbdbdb", "got:" .. got.selection)
		assert(got.light_foreground == "#737373", "got:" .. got.light_foreground)
	end,
}
