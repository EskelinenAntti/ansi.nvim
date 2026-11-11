local M = {}
local color = require("chameleon.color")

---@class Palette
---@field mode "dark"|"light"
---@field background string
---@field foreground string
---@field recessed_background string
---@field raised_background string
---@field highlight_background string Shared surface for menus, references, and matching parentheses
---@field shadow_background string
---@field muted string Low-emphasis UI text and decoration
---@field secondary_foreground string Readable secondary text
---@field emphasis_foreground string
---@field text_selection_foreground string Visual selection text
---@field text_selection_background string Visual selection surface, including the contrast fallback
---@field highlight_underline true|nil Underline highlighted items and references when their surface is indistinct
---@field accent string
---@field red string
---@field green string
---@field yellow string
---@field blue string
---@field magenta string
---@field cyan string
---@field diff_add_background string Added lines
---@field diff_change_background string Changed lines
---@field diff_delete_background string Deleted lines
---@field diff_add_inline_background string Added text within a line
---@field diff_change_inline_background string Changed text within a line
---@field diff_delete_inline_background string Deleted text within a line

---Map the terminal's ANSI colors and default colors into Palette.
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

	local recessed_background = surface(tones.lowest)
	local raised_background = surface(tones.low)
	local highlight_background = surface(tones.highest)

	-- Use the least contrasting surface so derived text also works in menus and selections.
	local text_background = background
	for _, candidate in ipairs({ recessed_background, raised_background, highlight_background }) do
		if color.contrast(candidate, foreground) < color.contrast(text_background, foreground) then
			text_background = candidate
		end
	end
	-- WCAG targets: 3:1 for muted UI and 4.5:1 for regular text.
	local muted = color.for_contrast(text_background, foreground, 3)
	local secondary_foreground = color.for_contrast(text_background, foreground, 4.5)

	---Keep terminal hues, correcting only accents that would be hard to read.
	---@param index integer
	---@param surface_color string|nil
	---@return string
	local function syntax(index, surface_color)
		surface_color = surface_color or raised_background
		local minimum_contrast = math.min(4.5, color.contrast(surface_color, foreground))
		local value = colors[index]
		if color.contrast(surface_color, value) >= minimum_contrast then
			return value
		end
		local target = color.for_contrast(surface_color, foreground, minimum_contrast)
		return color.with_tone(value, color.tone(target), mode == "dark" and "up" or "down")
	end

	local emphasis_foreground = mode == "light" and foreground or colors[15]
	if color.contrast(text_background, emphasis_foreground) < color.contrast(text_background, foreground) then
		emphasis_foreground = foreground
	end

	-- Contrast-limited palettes need explicit selection cues instead of an indistinct surface.
	local highlight_tone = color.tone(highlight_background)
	local weak_selection = math.abs(highlight_tone - tone) < 2
	local red, green, yellow = syntax(1), syntax(2), syntax(3)
	local highlight_contrast = color.contrast(background, highlight_background)

	---Tint diff surfaces within the palette's selection contrast budget.
	---@param accent string
	---@param strength number
	---@return string
	local function diff_background(accent, strength)
		local tint = color.for_contrast(background, accent, 1 + (highlight_contrast - 1) * strength)
		local target = tone + (highlight_tone - tone) * strength
		return color.with_tone(tint, target, mode == "dark" and "down" or "up")
	end

	return {
		mode = mode,
		background = background,
		foreground = foreground,
		recessed_background = recessed_background,
		raised_background = raised_background,
		highlight_background = highlight_background,
		shadow_background = mode == "light" and foreground or surface(tones.lowest + tones.lowest - tones.surface),
		muted = muted,
		secondary_foreground = secondary_foreground,
		emphasis_foreground = emphasis_foreground,
		text_selection_foreground = weak_selection and background or foreground,
		text_selection_background = weak_selection and foreground or highlight_background,
		highlight_underline = weak_selection or nil,
		accent = syntax(4, text_background),
		red = red,
		green = green,
		yellow = yellow,
		blue = syntax(4),
		magenta = syntax(5),
		cyan = syntax(6),
		diff_add_background = diff_background(green, 0.5),
		diff_change_background = diff_background(yellow, 0.5),
		diff_delete_background = diff_background(red, 0.5),
		diff_add_inline_background = diff_background(green, 1),
		diff_change_inline_background = diff_background(yellow, 1),
		diff_delete_inline_background = diff_background(red, 1),
	}
end

return M
