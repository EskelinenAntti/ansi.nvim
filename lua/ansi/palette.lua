local M = {}

---@param color string
---@return number[]
local function channels(color)
	return {
		tonumber(color:sub(2, 3), 16),
		tonumber(color:sub(4, 5), 16),
		tonumber(color:sub(6, 7), 16),
	}
end

---@param from string
---@param to string
---@param amount number
---@return string
local function blend(from, to, amount)
	local a, b = channels(from), channels(to)
	return string.format(
		"#%02x%02x%02x",
		math.floor(a[1] + (b[1] - a[1]) * amount + 0.5),
		math.floor(a[2] + (b[2] - a[2]) * amount + 0.5),
		math.floor(a[3] + (b[3] - a[3]) * amount + 0.5)
	)
end

---@param color string
---@return number
local function brightness(color)
	local rgb = channels(color)
	return 0.299 * rgb[1] + 0.587 * rgb[2] + 0.114 * rgb[3]
end

---Map the terminal's ANSI colors and default colors into Palette.
---@param colors table Raw terminal colors, with ANSI indices starting at 0
---@return Palette
function M.palette_for(colors)
	local background = colors.background or colors[0]
	local foreground = colors.foreground or colors[7]
	local mode = brightness(background) > brightness(foreground) and "light" or "dark"
	local edge = mode == "light" and "#ffffff" or "#000000"

	return {
		mode = mode,
		accent = colors[4],
		selection = blend(background, foreground, 0.14),
		muted = blend(background, foreground, 0.35),
		background = background,
		dark_background = blend(background, edge, 0.12),
		darker_background = blend(background, edge, 0.24),
		lighter_background = blend(background, foreground, 0.04),
		foreground = foreground,
		dark_foreground = blend(background, foreground, 0.35),
		light_foreground = blend(background, foreground, 0.55),
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
