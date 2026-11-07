local M = {}

-- sRGB transfer functions and relative luminance from WCAG:
-- https://www.w3.org/WAI/WCAG21/Techniques/general/G18
local function linear(channel)
	channel = channel / 255
	if channel <= 0.04045 then
		return channel / 12.92
	end
	return ((channel + 0.055) / 1.055) ^ 2.4
end

local function channels(color)
	return {
		linear(tonumber(color:sub(2, 3), 16)),
		linear(tonumber(color:sub(4, 5), 16)),
		linear(tonumber(color:sub(6, 7), 16)),
	}
end

local function encoded(channel, rounding)
	channel = math.max(0, math.min(1, channel))
	if channel == 0 or channel == 1 then
		return channel * 255
	end
	if channel <= 0.0031308 then
		channel = 12.92 * channel
	else
		channel = 1.055 * channel ^ (1 / 2.4) - 0.055
	end
	if rounding == "up" then
		return math.min(255, math.ceil(channel * 255))
	elseif rounding == "down" then
		return math.max(0, math.floor(channel * 255))
	end
	return math.floor(channel * 255 + 0.5)
end

---@param color string
---@return number
function M.luminance(color)
	local rgb = channels(color)
	return 0.2126 * rgb[1] + 0.7152 * rgb[2] + 0.0722 * rgb[3]
end

---@param first string
---@param second string
---@return number
function M.contrast(first, second)
	local a, b = M.luminance(first), M.luminance(second)
	return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
end

-- CIELAB L* (0..100), the tone scale used by Material Design.
-- https://github.com/material-foundation/material-color-utilities/blob/main/typescript/utils/color_utils.ts
---@param luminance number
---@return number
function M.tone_for_luminance(luminance)
	if luminance <= (6 / 29) ^ 3 then
		return (29 / 3) ^ 3 * luminance
	end
	return 116 * luminance ^ (1 / 3) - 16
end

---@param tone number
---@return number
local function luminance_for_tone(tone)
	tone = math.max(0, math.min(100, tone))
	if tone <= 8 then
		return tone / (29 / 3) ^ 3
	end
	return ((tone + 16) / 116) ^ 3
end

---@param color string
---@return number
function M.tone(color)
	return M.tone_for_luminance(M.luminance(color))
end

local function at_luminance(from, to, luminance, rounding)
	local a, b = channels(from), channels(to)
	local first, last = M.luminance(from), M.luminance(to)
	if first == last then
		return from
	end
	local amount = math.max(0, math.min(1, (luminance - first) / (last - first)))
	return string.format(
		"#%02x%02x%02x",
		encoded(a[1] + (b[1] - a[1]) * amount, rounding),
		encoded(a[2] + (b[2] - a[2]) * amount, rounding),
		encoded(a[3] + (b[3] - a[3]) * amount, rounding)
	)
end

---Adjust tone by mixing with black or white in linear RGB, keeping the color in gamut.
---@param color string
---@param tone number
---@param rounding "up"|"down"|nil
---@return string
function M.with_tone(color, tone, rounding)
	local target = luminance_for_tone(tone)
	local edge = target > M.luminance(color) and "#ffffff" or "#000000"
	return at_luminance(color, edge, target, rounding)
end

---Find the blend toward foreground that reaches the requested contrast against background.
---Keep foreground unchanged if the terminal palette cannot reach the target.
---@param background string
---@param foreground string
---@param ratio number
---@return string
function M.for_contrast(background, foreground, ratio)
	if M.contrast(background, foreground) <= ratio then
		return foreground
	end
	local bg, fg = M.luminance(background), M.luminance(foreground)
	local target = fg > bg and ratio * (bg + 0.05) - 0.05 or (bg + 0.05) / ratio - 0.05
	-- Round away from the background so 8-bit quantization does not undercut the target.
	return at_luminance(background, foreground, target, fg > bg and "up" or "down")
end

return M
