return {
	---Verify: Terminal ANSI colors are mapped to the same highlight palette as the other themes.
	["Terminal ANSI colors are mapped to the same highlight palette as the other themes"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.background = "#000000"
		local source = vim.deepcopy(colors)

		-- When
		local got = require("chameleon.palette").palette_for(colors)

		-- Then
		assert(got.background == colors.background)
		assert(got.foreground == colors.foreground)
		assert(got.accent == colors[4])
		assert(got.red == colors[1])
		assert(got.green == colors[2])
		assert(got.yellow == colors[3])
		assert(got.mode == "dark")
		assert(vim.deep_equal(colors, source), "Source colors were modified")
	end,

	---Verify: Use ANSI background and foreground when the terminal does not answer OSC 10 and 11.
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

	---Verify: Light themes keep readable foregrounds and derive light surfaces.
	["Light themes keep readable foregrounds and derive light surfaces"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.background = "#ffffff"
		colors.foreground = "#000000"

		-- When
		local got = require("chameleon.palette").palette_for(colors)

		-- Then
		assert(got.mode == "light")
		assert(got.emphasis_foreground == "#000000")
		local color = require("chameleon.color")
		assert(math.abs(color.tone(got.highlight_background) - 92) < 0.5)
		assert(math.abs(color.tone(got.raised_background) - 98) < 0.5)
		assert(color.contrast(got.highlight_background, got.secondary_foreground) >= 4.5)
	end,

	---Verify: Dark surfaces follow Material tonal spacing relative to the terminal background.
	["Dark surfaces follow Material tonal spacing relative to the terminal background"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		local color = require("chameleon.color")
		local baseline = color.tone(colors.background)

		-- When
		local got = require("chameleon.palette").palette_for(colors)

		-- Then
		assert(math.abs(color.tone(got.raised_background) - baseline - 4) < 0.5)
		assert(math.abs(color.tone(got.highlight_background) - baseline - 16) < 0.5)
		assert(math.abs(color.tone(got.recessed_background) - baseline + 2) < 0.5)
		assert(math.abs(color.tone(got.shadow_background) - baseline + 4) < 0.5)
	end,

	---Verify: Surface tones and derived text preserve contrast across light, dark, and low-contrast palettes.
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
			{ "#444444", "#ebdbb2" },
			{ "#666666", "#ebdbb2" },
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
				got.recessed_background,
				got.raised_background,
				got.highlight_background,
			}) do
				local available = color.contrast(surface, pair[2])
				assert(available >= minimum - 0.000001, "Surface reduced text contrast: " .. surface)
				assert(color.contrast(surface, got.secondary_foreground) >= math.min(4.5, available) - 0.000001)
				assert(color.contrast(surface, got.muted) >= math.min(3, available) - 0.000001)
			end
			for _, role in ipairs({ "red", "green", "yellow", "blue", "magenta", "cyan", "accent" }) do
				local available = color.contrast(got.raised_background, pair[2])
				assert(
					color.contrast(got.raised_background, got[role]) >= math.min(4.5, available),
					role .. " lost contrast"
				)
			end
			for _, role in ipairs({
				"diff_add_background",
				"diff_change_background",
				"diff_delete_background",
				"diff_add_word_background",
				"diff_change_word_background",
				"diff_delete_word_background",
			}) do
				assert(color.contrast(got[role], pair[2]) >= minimum - 0.000001, role .. " lost contrast")
			end
		end
	end,

	---Verify: Low-contrast light accents are corrected without changing readable colors or terminal colors.
	["Low-contrast light accents are corrected while readable colors are preserved"] = function()
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.background, colors.foreground = "#eff1f5", "#4c4f69"
		colors[5], colors[4] = "#ea76cb", "#1e40af"
		local source = vim.deepcopy(colors)

		local got = require("chameleon.palette").palette_for(colors)

		assert(require("chameleon.color").contrast(got.raised_background, got.magenta) >= 4.5)
		assert(got.magenta ~= colors[5])
		assert(got.blue == colors[4])
		assert(vim.deep_equal(colors, source), "Terminal colors were modified")
	end,

	---Verify: An unusually dark ANSI white cannot reduce emphasized text contrast.
	["Emphasized text never falls back to unreadable ANSI white"] = function()
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors[15] = colors.background

		local got = require("chameleon.palette").palette_for(colors)

		assert(got.emphasis_foreground == colors.foreground)
	end,

	---Verify: Theme mode uses linear-light luminance instead of encoded RGB brightness.
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
