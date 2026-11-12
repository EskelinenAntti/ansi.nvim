-- Derive readable text and quiet surfaces from the terminal palette.
local function channels(hex)
	local rgb = {}
	for i = 1, 3 do
		local v = tonumber(hex:sub(i * 2, i * 2 + 1), 16) / 255
		rgb[i] = v <= 0.04045 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
	end
	return rgb
end

local function luminance(rgb)
	return 0.2126 * rgb[1] + 0.7152 * rgb[2] + 0.0722 * rgb[3]
end

-- Mix with black or white in linear RGB to reach the desired luminance.
local function shade(hex, target, round)
	local rgb = channels(hex)
	local source = luminance(rgb)
	local edge = target > source and 1 or 0
	if source == edge then
		return hex
	end
	local amount = (target - source) / (edge - source)
	for i, v in ipairs(rgb) do
		v = v + (edge - v) * amount
		v = v <= 0.0031308 and 12.92 * v or 1.055 * v ^ (1 / 2.4) - 0.055
		rgb[i] = math.max(0, math.min(255, round(v * 255)))
	end
	return string.format("#%02x%02x%02x", unpack(rgb))
end

return function(colors)
	local bg, fg = colors.background or colors[0], colors.foreground or colors[7]
	local b, f = luminance(channels(bg)), luminance(channels(fg))
	local dark = f >= b
	local available = (math.max(b, f) + 0.05) / (math.min(b, f) + 0.05)
	local minimum = math.min(4.5, available)
	local away = dark and math.ceil or math.floor
	local toward = dark and math.floor or math.ceil

	-- One surface for floats, the active line, and diff tints. Preserve text contrast.
	local ratio = math.min(1.2, available / minimum)
	local surface_luminance = dark and (b + 0.05) * ratio - 0.05 or (b + 0.05) / ratio - 0.05
	local text = dark and (surface_luminance + 0.05) * minimum - 0.05 or (surface_luminance + 0.05) / minimum - 0.05

	local p = {
		mode = dark and "dark" or "light",
		bg = bg,
		fg = fg,
		surface = shade(bg, surface_luminance, toward),
		muted = shade(fg, text, away),
	}
	for i = 1, 6 do
		local accent = colors[i]
		local a = luminance(channels(accent))
		p[i] = (dark and a >= text or not dark and a <= text) and accent or shade(accent, text, away)
	end
	for i = 1, 3 do
		p["tint" .. i] = shade(p[i], surface_luminance, toward)
	end
	return p
end
