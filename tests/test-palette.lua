return {
	---Verify: Readable chromatic variants preserve terminal palette slots.
	["Readable chromatic variants preserve terminal palette slots"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.background = "#000000"
		local source = vim.deepcopy(colors)

		-- When
		local got = require("chameleon.palette").palette_for(colors)

		-- Then
		assert(got.background == colors.background)
		assert(got.foreground == colors.foreground)
		assert(got.accent_1 == colors[1])
		assert(got.accent_2 == colors[2])
		assert(got.accent_3 == colors[3])
		assert(got.accent_4 == colors[4])
		assert(got.accent_5 == colors[5])
		assert(got.accent_6 == colors[6])
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
		assert(got.foreground_emphasis == "#000000")
		local color = require("chameleon.color")
		assert(math.abs(color.tone(got.background_emphasis) - 92) < 0.5)
		assert(math.abs(color.tone(got.background_raised) - 98) < 0.5)
		assert(color.contrast(got.background_emphasis, got.foreground_muted) >= 4.5)
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
		assert(math.abs(color.tone(got.background_raised) - baseline - 4) < 0.5)
		assert(math.abs(color.tone(got.background_emphasis) - baseline - 16) < 0.5)
		assert(math.abs(color.tone(got.background_recessed) - baseline + 2) < 0.5)
		assert(math.abs(color.tone(got.background_deep) - baseline + 4) < 0.5)
	end,

	---Verify: Surface tones and derived text preserve contrast across light, dark, and low-contrast palettes.
	["Surface tones and derived text preserve contrast across light, dark, and low-contrast palettes"] = function()
		-- Given
		local color = require("chameleon.color")
		local color_pairs = {
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

		for _, pair in ipairs(color_pairs) do
			local colors = vim.deepcopy(require("tests.current.colors"))
			colors.background, colors.foreground = pair[1], pair[2]

			-- When
			local got = require("chameleon.palette").palette_for(colors)

			-- Then
			assert(got.background == pair[1] and got.foreground == pair[2])
			local minimum = math.min(4.5, color.contrast(pair[1], pair[2]))
			for _, surface in ipairs({
				got.background,
				got.background_recessed,
				got.background_raised,
				got.background_emphasis,
			}) do
				local available = color.contrast(surface, pair[2])
				assert(available >= minimum - 0.000001, "Surface reduced text contrast: " .. surface)
				assert(color.contrast(surface, got.foreground_muted) >= math.min(4.5, available) - 0.000001)
				assert(color.contrast(surface, got.foreground_subtle) >= math.min(3, available) - 0.000001)
				assert(color.contrast(surface, got.foreground_emphasis) >= minimum - 0.000001)
				for index = 1, 6 do
					local role = "accent_" .. index
					assert(color.contrast(surface, got[role]) >= minimum - 0.000001, role .. " lost contrast")
				end
			end
			assert(color.contrast(got.background_contrast, got.foreground_on_contrast) >= minimum - 0.000001)
			for _, role in ipairs({
				"accent_1_subtle",
				"accent_2_subtle",
				"accent_3_subtle",
				"accent_1_muted",
				"accent_2_muted",
				"accent_3_muted",
			}) do
				assert(color.contrast(got[role], pair[2]) >= minimum - 0.000001, role .. " lost contrast")
			end
		end
	end,

	---Verify: An accent readable on the emphasis surface must also remain readable on the default background.
	["All six accents preserve contrast across every editor surface"] = function()
		local color = require("chameleon.color")
		for _, pair in ipairs({
			{ "#555555", "#ffffff", "#000000" },
			{ "#888888", "#000000", "#ffffff" },
		}) do
			local colors = vim.deepcopy(require("tests.current.colors"))
			colors.background, colors.foreground = pair[1], pair[2]
			for index = 1, 6 do
				colors[index] = pair[3]
			end

			local got = require("chameleon.palette").palette_for(colors)

			assert(color.contrast(got.background_emphasis, pair[3]) >= 4.5)
			assert(color.contrast(got.background, pair[3]) < 4.5)
			for index = 1, 6 do
				local accent = got["accent_" .. index]
				assert(accent ~= colors[index])
				for _, surface in ipairs({
					got.background,
					got.background_recessed,
					got.background_raised,
					got.background_emphasis,
				}) do
					assert(color.contrast(surface, accent) >= 4.5)
				end
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

		assert(require("chameleon.color").contrast(got.background_raised, got.accent_5) >= 4.5)
		assert(got.accent_5 ~= colors[5])
		assert(got.accent_4 == colors[4])
		assert(vim.deep_equal(colors, source), "Terminal colors were modified")
	end,

	---Verify: ANSI white must preserve the default foreground's contrast on every editor surface.
	["Emphasized text preserves the default foreground contrast"] = function()
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.background, colors.foreground = "#555555", "#ffffff"
		colors[15] = "#000000"

		local got = require("chameleon.palette").palette_for(colors)

		assert(got.foreground_emphasis == colors.foreground)
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
