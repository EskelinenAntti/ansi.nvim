local api = vim.api
local colors = require("tests.colors")
local attached, requests, warnings
local defer = vim.defer_fn
api.nvim_ui_send = function(query)
	if query:find("\027]4;", 1, true) then
		requests[#requests + 1] = query
	end
end
api.nvim_list_uis = function()
	return attached and { { stdout_tty = true } } or {}
end
vim.notify = function(message)
	warnings[#warnings + 1] = message
end

local function test(name, run)
	vim.cmd.colorscheme("default")
	attached, requests, warnings = true, {}, {}
	vim.defer_fn = defer
	local ok, err = xpcall(run, debug.traceback)
	if not ok then
		io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
		os.exit(1)
	end
	print("PASS " .. name)
end

local function response(sequence)
	api.nvim_exec_autocmds("TermResponse", { data = { sequence = sequence } })
end

local function reply(source)
	-- Defaults first, ANSI in reverse order: replies need not follow query order.
	for _, key in ipairs({ "foreground", "background", 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }) do
		local hex = source[key]
		if hex then
			local command = type(key) == "number" and "4;" .. key or key == "foreground" and "10" or "11"
			response("\027]" .. command .. ";rgb:" .. hex:sub(2, 3) .. "/" .. hex:sub(4, 5) .. "/" .. hex:sub(6, 7))
		end
	end
end

local function apply(source)
	vim.cmd.colorscheme("chameleon")
	reply(source or colors)
end

local function hl(name)
	return api.nvim_get_hl(0, { name = name, link = false })
end

local function cleaned_up()
	assert(#api.nvim_get_autocmds({ group = "chameleon-query" }) == 0, "Query listeners remain active")
end

local function contrast(first, second)
	local function luminance(value)
		local sum = 0
		for i, weight in ipairs({ 0.2126, 0.7152, 0.0722 }) do
			local channel = math.floor(value / 256 ^ (3 - i)) % 256 / 255
			sum = sum + weight * (channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4)
		end
		return sum
	end
	local a, b = luminance(first), luminance(second)
	return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
end

local function number(hex)
	return tonumber(hex:sub(2), 16)
end

test("reads the terminal once, applies highlights, and preserves editor options", function()
	vim.opt.cursorline = false
	vim.env.TERM_PROGRAM = "any-terminal"
	api.nvim_set_hl(0, "OldThemeGroup", { fg = "#123456" })
	apply()
	assert(vim.g.colors_name == "chameleon" and vim.o.termguicolors)
	assert(hl("Normal").fg == number(colors.foreground) and hl("Normal").bg == number(colors.background))
	assert(not vim.o.cursorline)
	assert(not hl("OldThemeGroup").fg)
	for i = 0, 15 do
		assert(vim.g["terminal_color_" .. i] == colors[i])
		assert(requests[1]:find(string.format("\027]4;%d;?\027\\", i), 1, true))
	end
	assert(requests[1]:find("\027]10;?\027\\\027]11;?\027\\", 1, true))
	assert(#requests == 1)
	cleaned_up()
	local updated = vim.deepcopy(colors)
	updated.foreground = "#ffffff"
	reply(updated)
	assert(hl("Normal").fg == number(colors.foreground), "Unsolicited replies changed the theme")
	vim.cmd.colorscheme("chameleon")
	reply(updated)
	assert(#requests == 2 and hl("Normal").fg == 0xffffff)
	cleaned_up()
end)

test("notifies ColorScheme listeners after asynchronous highlights are ready", function()
	local observed = {}
	local id = api.nvim_create_autocmd("ColorScheme", {
		pattern = "chameleon",
		callback = function()
			observed[#observed + 1] = hl("Normal").fg
		end,
	})
	apply()
	api.nvim_del_autocmd(id)
	assert(#observed == 2 and observed[2] == number(colors.foreground))
end)

test("waits for UIEnter at startup and sends a single query", function()
	attached = false
	vim.cmd.colorscheme("chameleon")
	assert(#requests == 0)
	attached = true
	api.nvim_exec_autocmds("UIEnter", {})
	api.nvim_exec_autocmds("UIEnter", {})
	assert(#requests == 1)
	reply(colors)
	assert(hl("Normal").bg == number(colors.background))
	cleaned_up()
end)

test("ignores late responses after a colorscheme switch, including before UI attachment", function()
	for _, has_ui in ipairs({ true, false }) do
		attached = has_ui
		vim.cmd.colorscheme("chameleon")
		vim.cmd.colorscheme("default")
		local previous = hl("Normal")
		reply(colors)
		api.nvim_exec_autocmds("UIEnter", {})
		assert(vim.g.colors_name == "default" and vim.deep_equal(previous, hl("Normal")))
		cleaned_up()
	end
end)

test("a superseded query cannot finish through an already queued timeout", function()
	local stale
	vim.defer_fn = function(fn, ms)
		stale = fn
		return defer(fn, ms)
	end
	vim.cmd.colorscheme("chameleon")
	local old_timeout = stale
	vim.cmd.colorscheme("chameleon")
	old_timeout()
	assert(#warnings == 0)
	reply(colors)
	assert(hl("Normal").fg == number(colors.foreground))
	cleaned_up()
end)

test("accepts one to four hex digits and scales full channel values", function()
	vim.cmd.colorscheme("chameleon")
	response("\027]4;1;rgb:f/8/0")
	response("\027]4;2;rgb:ff/88/00")
	response("\027]4;3;rgb:fff/888/000")
	response("\027]4;4;rgb:ffff/8888/0000")
	response("\027]4;5;rgb:8000/0000/ffff")
	local remaining = vim.deepcopy(colors)
	for i = 1, 5 do
		remaining[i] = nil
	end
	reply(remaining)
	for i = 1, 4 do
		assert(vim.g["terminal_color_" .. i] == "#ff8800")
	end
	assert(vim.g.terminal_color_5 == "#8000ff")
	cleaned_up()
end)

test("malformed, unrelated, and duplicate replies cannot complete a partial palette", function()
	vim.cmd.colorscheme("chameleon")
	local previous = hl("Normal")
	for _, sequence in ipairs({
		"\027P>|Rex",
		"\027]4;16;rgb:ff/ff/ff",
		"\027]4;1;rgb:fffff/ff/ff",
		"\027]4;1;rgb:zz/ff/ff",
		"\027]4;1;rgb:ff/ff/ff;text",
		"\027]4;invalid",
		"\027]12;rgb:ff/ff/ff",
		"\027]10;1;rgb:ff/ff/ff",
		"\027]11;;rgb:ff/ff/ff",
		"\027]4;-1;rgb:ff/ff/ff",
		"\027]4;1;rgb:/ff/ff",
	}) do
		response(sequence)
	end
	local partial = vim.deepcopy(colors)
	partial[1] = nil
	reply(partial)
	reply(partial)
	assert(vim.deep_equal(hl("Normal"), previous))
	response("\027]4;1;rgb:dd/7a/72")
	assert(hl("Normal").fg == number(colors.foreground))
	cleaned_up()
end)

test("falls back to ANSI defaults when OSC 10/11 are unsupported", function()
	local ansi = vim.deepcopy(colors)
	ansi.foreground, ansi.background = nil, nil
	apply(ansi)
	assert(vim.wait(1500, function()
		return hl("Normal").bg == number(ansi[0])
	end))
	assert(hl("Normal").fg == number(ansi[7]) and #warnings == 0, vim.inspect({ hl("Normal"), warnings }))
	cleaned_up()
end)

test("an incomplete query preserves all previous highlights and releases its listeners", function()
	apply()
	local previous = api.nvim_get_hl(0, {})
	vim.cmd.colorscheme("chameleon")
	response("\027]4;0;rgb:ff/ff/ff")
	assert(vim.wait(1500, function()
		return #warnings == 1
	end))
	assert(vim.deep_equal(previous, api.nvim_get_hl(0, {})))
	cleaned_up()
end)

test("default links carry the palette into Treesitter, LSP, and diagnostic variants", function()
	apply()
	for i, name in ipairs({ "DiagnosticError", "String", "Type", "Function", "Statement", "Special" }) do
		assert(hl(name).fg == number(colors[i]), "A readable accent was changed")
	end
	for name, parent in pairs({
		["@function"] = "Function",
		["@keyword"] = "Statement",
		["@type"] = "Type",
		["@lsp.type.function"] = "Function",
		["@lsp.type.property"] = "Function",
		DiagnosticSignError = "DiagnosticError",
		DiagnosticVirtualTextWarn = "DiagnosticWarn",
		DiagnosticFloatingInfo = "DiagnosticInfo",
		Directory = "Function",
		LspCodeLens = "NonText",
		VisualNOS = "Visual",
		WildMenu = "PmenuSel",
	}) do
		assert(vim.deep_equal(hl(name), hl(parent)), name .. " lost its palette")
	end
	assert(hl("MatchParen").underline and hl("LspReferenceRead").underline)
end)

test("keeps readable colors and contrast across dark, light, tinted, and low-contrast palettes", function()
	for _, pair in ipairs({
		{ "#14181a", "#d2dbdc" },
		{ "#eff1f5", "#4c4f69", "light" },
		{ "#282828", "#ebdbb2" },
		{ "#000000", "#ffffff" },
		{ "#ffffff", "#000000", "light" },
		{ "#555555", "#ffffff" },
		{ "#888888", "#000000", "light" },
		{ "#004488", "#ddeeff" },
		{ "#ffcc88", "#332211", "light" },
		{ "#444444", "#555555" },
		{ "#555555", "#444444", "light" },
		{ "#444444", "#444444" },
		{ "#ff0000", "#777777", "light" },
		{ "#34c0df", "#ba7fab", "light", "#9ddfee" },
	}) do
		local source = vim.deepcopy(colors)
		source.background, source.foreground = pair[1], pair[2]
		-- Also exercise accents on the opposite side of the background's luminance.
		source[1], source[5] = "#000000", "#ea76cb"
		source[4] = pair[4] or source[4]
		apply(source)
		local normal = hl("Normal")
		assert(normal.bg == number(pair[1]) and normal.fg == number(pair[2]))
		local minimum = math.min(4.5, contrast(normal.bg, normal.fg))
		local surfaces = {
			normal.bg,
			hl("CursorLine").bg,
			hl("NormalFloat").bg,
			hl("DiffAdd").bg,
			hl("DiffChange").bg,
			hl("DiffDelete").bg,
		}
		for _, bg in ipairs(surfaces) do
			assert(contrast(bg, normal.fg) >= minimum - 1e-6, pair[1] .. " surface lost contrast")
			assert(contrast(bg, hl("Comment").fg) >= minimum - 1e-6, pair[1] .. " comment lost contrast")
			assert(contrast(bg, hl("NonText").fg) >= math.min(3, minimum) - 1e-6)
			for _, name in ipairs({ "DiagnosticError", "String", "Type", "Function", "Statement", "Special" }) do
				assert(contrast(bg, hl(name).fg) >= minimum - 1e-6, pair[1] .. " " .. name .. " lost contrast")
			end
		end
		local selection = hl("Visual")
		assert(selection.bg == normal.fg and selection.fg == normal.bg)
		assert(vim.o.background == (pair[3] or "dark"))
		for i = 1, 6 do
			assert(vim.g["terminal_color_" .. i] == source[i], "Terminal colors were changed")
		end
		cleaned_up()
	end
end)

vim.cmd.colorscheme("default")
print("All tests passed")
