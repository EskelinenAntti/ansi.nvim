return {
	["Terminal ANSI colors are mapped to the same highlight palette as the other themes"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))

		-- When
		local got = require("chameleon.palette").palette_for(colors)

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
		local got = require("chameleon.palette").palette_for(colors)

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
		local got = require("chameleon.palette").palette_for(colors)

		-- Then
		assert(got.mode == "light")
		assert(got.bright_foreground == "#000000")
		local color = require("chameleon.color")
		assert(math.abs(color.tone(got.selection) - 92) < 0.5)
		assert(math.abs(color.tone(got.lighter_background) - 98) < 0.5)
		assert(color.contrast(got.selection, got.light_foreground) >= 4.5)
	end,

	["Dark surfaces follow Material tonal spacing relative to the terminal background"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		local color = require("chameleon.color")
		local baseline = color.tone(colors.background)

		-- When
		local got = require("chameleon.palette").palette_for(colors)

		-- Then
		assert(math.abs(color.tone(got.lighter_background) - baseline - 4) < 0.5)
		assert(math.abs(color.tone(got.selection) - baseline - 16) < 0.5)
		assert(math.abs(color.tone(got.dark_background) - baseline + 2) < 0.5)
		assert(math.abs(color.tone(got.darker_background) - baseline + 4) < 0.5)
	end,

	["Surface tones and derived text preserve contrast across light, dark, and low-contrast palettes"] = function()
		-- Given
		local color = require("chameleon.color")
		local pairs = {
			{ "#000000", "#ffffff" },
			{ "#ffffff", "#000000" },
			{ "#555555", "#ffffff" },
			{ "#777777", "#000000" },
			{ "#004488", "#ddeeff" },
			{ "#ffcc88", "#332211" },
			{ "#444444", "#555555" },
			{ "#555555", "#444444" },
			{ "#444444", "#444444" },
		}

		for _, pair in ipairs(pairs) do
			local colors = vim.deepcopy(require("tests.current.colors"))
			colors.background, colors.foreground = pair[1], pair[2]

			-- When
			local got = require("chameleon.palette").palette_for(colors)

			-- Then
			assert(got.background == pair[1] and got.foreground == pair[2])
			local minimum = math.min(4.5, color.contrast(pair[1], pair[2]))
			for _, surface in ipairs({
				got.background,
				got.dark_background,
				got.darker_background,
				got.lighter_background,
				got.selection,
			}) do
				local available = color.contrast(surface, pair[2])
				assert(available >= minimum - 0.000001, "Surface reduced text contrast: " .. surface)
				assert(color.contrast(surface, got.light_foreground) >= math.min(4.5, available) - 0.000001)
				assert(color.contrast(surface, got.muted) >= math.min(3, available) - 0.000001)
			end
		end
	end,

	["Theme mode uses linear-light luminance instead of encoded RGB brightness"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.background = "#ff0000"
		colors.foreground = "#777777"

		-- When
		local got = require("chameleon.palette").palette_for(colors)

		-- Then
		assert(got.mode == "light")
	end,
}
