local M = {}
local color = require("chameleon.color")

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
	local function surface(target)
		target = tone + target - tones.surface
		target = mode == "dark" and math.min(target, limit_tone) or math.max(target, limit_tone)
		return color.with_tone(background, target, mode == "dark" and "down" or "up")
	end

	local dark_background = surface(tones.lowest)
	-- Repeat the lowest-surface step for the deeper surface role.
	local darker_background = surface(tones.lowest + tones.lowest - tones.surface)
	local lighter_background = surface(tones.low)
	local selection = surface(tones.highest)

	-- Use the least contrasting surface so derived text also works in menus and selections.
	local text_background = background
	for _, candidate in ipairs({ dark_background, lighter_background, selection }) do
		if color.contrast(candidate, foreground) < color.contrast(text_background, foreground) then
			text_background = candidate
		end
	end
	-- WCAG targets: 3:1 for muted UI and 4.5:1 for regular text.
	local muted = color.for_contrast(text_background, foreground, 3)
	local light_foreground = color.for_contrast(text_background, foreground, 4.5)

	return {
		mode = mode,
		accent = colors[4],
		selection = selection,
		muted = muted,
		background = background,
		dark_background = dark_background,
		darker_background = darker_background,
		lighter_background = lighter_background,
		foreground = foreground,
		dark_foreground = muted,
		light_foreground = light_foreground,
		bright_foreground = mode == "light" and foreground or colors[15],
		red = colors[1],
		green = colors[2],
		yellow = colors[3],
		orange = colors[3],
		blue = colors[4],
		magenta = colors[5],
		cyan = colors[6],
		bright_red = colors[9],
		bright_green = colors[10],
		bright_yellow = colors[11],
		bright_blue = colors[12],
		bright_magenta = colors[13],
		bright_cyan = colors[14],
	}
end

return M
