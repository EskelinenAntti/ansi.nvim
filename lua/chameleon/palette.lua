local M = {}
local color = require("chameleon.color")

-- Accent numbers identify terminal palette slots, not brightness ranks or syntax categories.
---@class Palette
---@field mode "dark"|"light" Appearance inferred from default foreground/background luminance
---@field background string Unmodified default background
---@field background_recessed string Background tone shifted away from the default foreground
---@field background_raised string Background tone shifted slightly toward the default foreground
---@field background_emphasis string Background tone with a larger shift toward the default foreground
---@field background_deep string Deep shade; derived from the background in dark mode and foreground in light mode
---@field foreground string Unmodified default foreground
---@field foreground_muted string Default foreground blended toward a 4.5:1 contrast target
---@field foreground_subtle string Fainter foreground blended toward a 3:1 contrast target
---@field foreground_emphasis string Foreground variant checked against the least-contrasting surface
---@field foreground_on_contrast string Foreground paired with background_contrast
---@field background_contrast string Contrasting surface, inverting the default colors when the emphasis tone is too flat
---@field background_emphasis_is_subtle true|nil True when background_emphasis differs from background by less than two L* tones
---@field accent_1 string High-contrast chromatic variant from terminal slot 1
---@field accent_2 string High-contrast chromatic variant from terminal slot 2
---@field accent_3 string High-contrast chromatic variant from terminal slot 3
---@field accent_4 string High-contrast chromatic variant from terminal slot 4
---@field accent_5 string High-contrast chromatic variant from terminal slot 5
---@field accent_6 string High-contrast chromatic variant from terminal slot 6
---@field accent_4_emphasis string Family 4 checked against the least-contrasting surface
---@field accent_1_subtle string Low-contrast background tint in family 1
---@field accent_2_subtle string Low-contrast background tint in family 2
---@field accent_3_subtle string Low-contrast background tint in family 3
---@field accent_1_muted string Stronger background tint in family 1
---@field accent_2_muted string Stronger background tint in family 2
---@field accent_3_muted string Stronger background tint in family 3

---Derive foreground, background, and accent variants from the terminal's colors.
---@param colors table Raw terminal colors, with ANSI indices starting at 0
---@return Palette
function M.palette_for(colors)
	local background = colors.background or colors[0]
	local foreground = colors.foreground or colors[7]
	local bg, fg = color.luminance(background), color.luminance(foreground)
	local mode = bg > fg and "light" or "dark"

	-- Material 3 surface tones, translated relative to the terminal's own background tone.
	-- https://github.com/material-components/material-components-android/blob/master/docs/theming/Color.md
	local tones = mode == "dark" and { surface = 6, lowest = 4, low = 10, highest = 22 }
		or { surface = 98, lowest = 100, low = 96, highest = 90 }
	local tone = color.tone(background)

	-- Surface changes must retain 4.5:1 foreground contrast, or the original contrast if lower.
	local minimum = math.min(4.5, color.contrast(background, foreground))
	local limit = mode == "dark" and (fg + 0.05) / minimum - 0.05 or minimum * (fg + 0.05) - 0.05
	local limit_tone = color.tone_for_luminance(limit)
	---Derive a surface color while preserving foreground contrast.
	---@param target number Material surface tone (0–100)
	---@return string
	local function surface(target)
		target = tone + target - tones.surface
		target = mode == "dark" and math.min(target, limit_tone) or math.max(target, limit_tone)
		return color.with_tone(background, target, mode == "dark" and "down" or "up")
	end

	local background_recessed = surface(tones.lowest)
	local background_raised = surface(tones.low)
	local background_emphasis = surface(tones.highest)

	-- Use the least-contrasting surface when deriving foreground variants.
	local text_background = background
	for _, candidate in ipairs({ background_recessed, background_raised, background_emphasis }) do
		if color.contrast(candidate, foreground) < color.contrast(text_background, foreground) then
			text_background = candidate
		end
	end
	-- WCAG targets: 3:1 for subtle tones and 4.5:1 for muted text.
	local foreground_subtle = color.for_contrast(text_background, foreground, 3)
	local foreground_muted = color.for_contrast(text_background, foreground, 4.5)

	---Keep terminal hues, correcting only accents that would be hard to read.
	---@param index integer
	---@param surface_color string|nil
	---@return string
	local function readable_accent(index, surface_color)
		surface_color = surface_color or background_raised
		local minimum_contrast = math.min(4.5, color.contrast(surface_color, foreground))
		local value = colors[index]
		if color.contrast(surface_color, value) >= minimum_contrast then
			return value
		end
		local target = color.for_contrast(surface_color, foreground, minimum_contrast)
		return color.with_tone(value, color.tone(target), mode == "dark" and "up" or "down")
	end

	local foreground_emphasis = mode == "light" and foreground or colors[15]
	if color.contrast(text_background, foreground_emphasis) < color.contrast(text_background, foreground) then
		foreground_emphasis = foreground
	end

	-- A nearly flat emphasis tone needs a more distinct contrast pair.
	local emphasis_tone = color.tone(background_emphasis)
	local emphasis_is_subtle = math.abs(emphasis_tone - tone) < 2
	-- Accents keep stable identities from terminal slots 1–6.
	local red, green, yellow = readable_accent(1), readable_accent(2), readable_accent(3)
	local blue, magenta, cyan = readable_accent(4), readable_accent(5), readable_accent(6)
	local emphasis_contrast = color.contrast(background, background_emphasis)

	---Mix a chromatic variant toward the background within the emphasis surface's contrast budget.
	---@param accent string
	---@param strength number
	---@return string
	local function muted_accent(accent, strength)
		local tint = color.for_contrast(background, accent, 1 + (emphasis_contrast - 1) * strength)
		local target = tone + (emphasis_tone - tone) * strength
		return color.with_tone(tint, target, mode == "dark" and "down" or "up")
	end

	return {
		mode = mode,
		background = background,
		background_recessed = background_recessed,
		background_raised = background_raised,
		background_emphasis = background_emphasis,
		background_deep = mode == "light" and foreground or surface(tones.lowest + tones.lowest - tones.surface),
		foreground = foreground,
		foreground_muted = foreground_muted,
		foreground_subtle = foreground_subtle,
		foreground_emphasis = foreground_emphasis,
		foreground_on_contrast = emphasis_is_subtle and background or foreground,
		background_contrast = emphasis_is_subtle and foreground or background_emphasis,
		background_emphasis_is_subtle = emphasis_is_subtle or nil,
		accent_1 = red,
		accent_2 = green,
		accent_3 = yellow,
		accent_4 = blue,
		accent_5 = magenta,
		accent_6 = cyan,
		accent_4_emphasis = readable_accent(4, text_background),
		accent_1_subtle = muted_accent(red, 0.5),
		accent_2_subtle = muted_accent(green, 0.5),
		accent_3_subtle = muted_accent(yellow, 0.5),
		accent_1_muted = muted_accent(red, 1),
		accent_2_muted = muted_accent(green, 1),
		accent_3_muted = muted_accent(yellow, 1),
	}
end

return M
