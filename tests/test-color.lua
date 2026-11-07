return {
	["Relative luminance and contrast match WCAG reference colors"] = function()
		-- Given
		local color = require("chameleon.color")
		local samples = {
			{ "#000000", 0 },
			{ "#ffffff", 1 },
			{ "#ff0000", 0.2126 },
			{ "#00ff00", 0.7152 },
			{ "#0000ff", 0.0722 },
			{ "#777777", 0.18447499450044 },
		}

		for _, sample in ipairs(samples) do
			-- When
			local got = color.luminance(sample[1])

			-- Then
			assert(math.abs(got - sample[2]) < 0.000001, "Unexpected luminance for " .. sample[1])
		end
		assert(math.abs(color.contrast("#000000", "#ffffff") - 21) < 0.000001)
		assert(color.contrast("#777777", "#777777") == 1)
	end,

	["CIELAB tones match the neutral reference scale"] = function()
		-- Given
		local color = require("chameleon.color")

		-- Then
		assert(color.tone("#000000") == 0)
		assert(math.abs(color.tone("#ffffff") - 100) < 0.000001)
		assert(math.abs(color.tone("#777777") - 50.03443879) < 0.000001)
		assert(color.with_tone("#000000", 50) == "#777777")
	end,

	["Tone adjustments stay in gamut and reach the requested perceptual lightness"] = function()
		-- Given
		local color = require("chameleon.color")
		local sources = { "#000000", "#ffffff", "#ff0000", "#005577", "#ffeecc" }

		for _, source in ipairs(sources) do
			for _, tone in ipairs({ 0, 5, 25, 50, 75, 95, 100 }) do
				-- When
				local got = color.with_tone(source, tone)

				-- Then
				assert(got:match("^#%x%x%x%x%x%x$"), "Invalid color: " .. got)
				assert(math.abs(color.tone(got) - tone) < 0.5, "Unexpected tone for " .. got)
			end
		end
		assert(color.with_tone("#005577", -10) == "#000000")
		assert(color.with_tone("#005577", 110) == "#ffffff")
		assert(color.with_tone("#ff0000", 100, "down") == "#ffffff")
		assert(color.with_tone("#ff0000", 0, "up") == "#000000")
	end,

	["Derived text meets contrast targets after rounding to 8-bit RGB"] = function()
		-- Given
		local color = require("chameleon.color")
		local pairs = {
			{ "#000000", "#ffffff" },
			{ "#ffffff", "#000000" },
			{ "#14181a", "#d2dbdc" },
			{ "#004488", "#ddeeff" },
			{ "#ffeecc", "#332211" },
		}

		for _, pair in ipairs(pairs) do
			for _, ratio in ipairs({ 3, 4.5 }) do
				-- When
				local got = color.for_contrast(pair[1], pair[2], ratio)

				-- Then
				local contrast = color.contrast(pair[1], got)
				assert(contrast >= ratio, "Contrast below target: " .. contrast)
				assert(contrast < ratio + 0.15, "Derived color is unnecessarily bright or dark")
			end
		end
	end,

	["Unreachable contrast targets preserve the terminal foreground"] = function()
		-- Given
		local color = require("chameleon.color")

		-- When
		local low_contrast = color.for_contrast("#444444", "#555555", 4.5)
		local identical = color.for_contrast("#444444", "#444444", 4.5)

		-- Then
		assert(low_contrast == "#555555")
		assert(identical == "#444444")
	end,
}
