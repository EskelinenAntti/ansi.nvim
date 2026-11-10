local M = {}
local color = require("chameleon.color")
---@class Palette
---@field mode "dark"|"light"
---@field accent string
---@field selection string
---@field muted string
---@field background string
---@field dark_background string
---@field darker_background string
---@field lighter_background string
---@field foreground string
---@field dark_foreground string
---@field light_foreground string
---@field bright_foreground string
---@field red string
---@field yellow string
---@field orange string
---@field green string
---@field cyan string
---@field blue string
---@field magenta string
---@field bright_red string
---@field bright_yellow string
---@field bright_green string
---@field bright_cyan string
---@field bright_blue string
---@field bright_magenta string

---Build highlight definitions from the palette.
---@param p Palette
---@return table<string, vim.api.keyset.highlight>
function M.highlights_for(p)
	-- Contrast-limited palettes can leave the selection surface nearly identical to the editor.
	local weak_selection = math.abs(color.tone(p.selection) - color.tone(p.background)) < 2
	local selection_fg = weak_selection and p.background or p.foreground
	local selection_bg = weak_selection and p.foreground or p.selection

	---Tint diff surfaces within the palette's selection contrast budget.
	---@param accent string
	---@param strength number
	---@return string
	local function diff_background(accent, strength)
		local contrast = color.contrast(p.background, p.selection)
		local tint = color.for_contrast(p.background, accent, 1 + (contrast - 1) * strength)
		local tone = color.tone(p.background) + (color.tone(p.selection) - color.tone(p.background)) * strength
		return color.with_tone(tint, tone, p.mode == "dark" and "down" or "up")
	end

	local highlights = {
		Added = { fg = p.green },
		Boolean = { fg = p.orange },
		Changed = { fg = p.yellow },
		Character = { fg = p.green },
		CmpItemAbbr = { fg = p.foreground },
		CmpItemAbbrDeprecated = { fg = p.light_foreground, strikethrough = true },
		CmpItemAbbrMatch = { fg = p.accent, bold = true },
		CmpItemAbbrMatchFuzzy = { fg = p.accent, bold = true },
		CmpItemKind = { fg = p.cyan },
		CmpItemMenu = { fg = p.light_foreground, italic = true },
		ColorColumn = { bg = p.lighter_background },
		Comment = { fg = p.light_foreground, italic = true },
		Conceal = { fg = p.muted },
		Conditional = { fg = p.magenta },
		Constant = { fg = p.orange },
		CurSearch = { fg = p.background, bg = p.accent, bold = true },
		Cursor = { fg = p.background, bg = p.bright_foreground },
		CursorColumn = { bg = p.lighter_background },
		CursorLine = { bg = p.lighter_background },
		CursorLineNr = { fg = p.accent, bg = p.lighter_background, bold = true },
		Debug = { fg = p.red },
		Define = { fg = p.cyan },
		Delimiter = { fg = p.foreground },
		DiagnosticError = { fg = p.red },
		DiagnosticDeprecated = { strikethrough = true },
		DiagnosticHint = { fg = p.cyan },
		DiagnosticInfo = { fg = p.blue },
		DiagnosticOk = { fg = p.green },
		DiagnosticSignError = { fg = p.red },
		DiagnosticSignHint = { fg = p.cyan },
		DiagnosticSignInfo = { fg = p.blue },
		DiagnosticSignWarn = { fg = p.yellow },
		DiagnosticUnderlineError = { sp = p.red, undercurl = true },
		DiagnosticUnderlineHint = { sp = p.cyan, undercurl = true },
		DiagnosticUnderlineInfo = { sp = p.blue, undercurl = true },
		DiagnosticUnderlineOk = { sp = p.green, undercurl = true },
		DiagnosticUnderlineWarn = { sp = p.yellow, undercurl = true },
		DiagnosticVirtualTextError = { fg = p.red, italic = true },
		DiagnosticVirtualTextHint = { fg = p.cyan, italic = true },
		DiagnosticVirtualTextInfo = { fg = p.blue, italic = true },
		DiagnosticVirtualTextOk = { fg = p.green, italic = true },
		DiagnosticVirtualTextWarn = { fg = p.yellow, italic = true },
		DiagnosticWarn = { fg = p.yellow },
		DiffAdd = { bg = diff_background(p.green, 0.5) },
		DiffChange = { bg = diff_background(p.yellow, 0.5) },
		DiffDelete = { fg = p.red, bg = diff_background(p.red, 0.5) },
		DiffText = { fg = p.foreground, bg = diff_background(p.yellow, 1), bold = true },
		Directory = { fg = p.blue, bold = true },
		EndOfBuffer = { fg = p.dark_background },
		Error = { fg = p.red, bold = true },
		ErrorMsg = { fg = p.red, bold = true },
		Exception = { fg = p.red },
		Float = { fg = p.orange },
		FloatBorder = { fg = p.muted, bg = p.lighter_background },
		FloatShadow = { bg = p.mode == "light" and p.foreground or p.darker_background, blend = 80 },
		FloatTitle = { fg = p.accent, bg = p.lighter_background, bold = true },
		FoldColumn = { fg = p.muted },
		Folded = { fg = p.light_foreground, bg = p.dark_background, italic = true },
		Function = { fg = p.blue },
		GitSignsAdd = { fg = p.green },
		GitSignsAddInline = { fg = p.foreground, bg = diff_background(p.green, 1), bold = true },
		GitSignsChange = { fg = p.yellow },
		GitSignsChangeInline = { link = "DiffText" },
		GitSignsDelete = { fg = p.red },
		GitSignsDeleteInline = { fg = p.foreground, bg = diff_background(p.red, 1), strikethrough = true },
		HealthError = { fg = p.red, bold = true },
		HealthSuccess = { fg = p.green, bold = true },
		HealthWarning = { fg = p.yellow, bold = true },
		Identifier = { fg = p.foreground },
		IncSearch = { link = "CurSearch" },
		Include = { fg = p.cyan },
		Keyword = { fg = p.magenta },
		Label = { fg = p.cyan },
		LineNr = { fg = p.muted },
		LspCodeLens = { fg = p.light_foreground, italic = true },
		LspCodeLensSeparator = { fg = p.muted },
		LspInlayHint = { fg = p.light_foreground, bg = p.dark_background, italic = true },
		LspReferenceRead = { bg = p.selection, underline = weak_selection or nil },
		LspReferenceText = { bg = p.selection, underline = weak_selection or nil },
		LspReferenceWrite = { bg = p.selection, bold = true, underline = weak_selection or nil },
		LspSignatureActiveParameter = { fg = p.bright_foreground, bg = p.selection, bold = true },
		Macro = { fg = p.cyan },
		MatchParen = { fg = p.foreground, bg = p.selection, bold = true, underline = true },
		ModeMsg = { fg = p.foreground, bold = true },
		MoreMsg = { fg = p.cyan, bold = true },
		MsgArea = { fg = p.foreground, bg = p.background },
		NonText = { fg = p.muted },
		Normal = { fg = p.foreground, bg = p.background },
		NormalFloat = { fg = p.foreground, bg = p.lighter_background },
		NormalNC = { fg = p.foreground, bg = p.dark_background },
		Number = { fg = p.orange },
		OkMsg = { fg = p.green },
		Operator = { fg = p.cyan },
		Pmenu = { fg = p.foreground, bg = p.lighter_background },
		PmenuExtra = { fg = p.light_foreground, italic = true },
		PmenuExtraSel = { fg = p.light_foreground, italic = true },
		PmenuKind = { fg = p.cyan },
		PmenuKindSel = { fg = p.foreground },
		PmenuMatch = { fg = p.accent, bold = true },
		PmenuMatchSel = { fg = p.accent, bold = true },
		PmenuSbar = { bg = p.selection },
		PmenuSel = { fg = p.foreground, bg = p.selection, underline = weak_selection or nil },
		PmenuThumb = { bg = p.muted },
		PreCondit = { fg = p.cyan },
		PreProc = { fg = p.cyan },
		Question = { fg = p.green, bold = true },
		QuickFixLine = { fg = p.foreground, bg = p.selection, underline = weak_selection or nil },
		Removed = { fg = p.red },
		Repeat = { fg = p.magenta },
		Search = { fg = p.background, bg = p.yellow, bold = true },
		SignColumn = { fg = p.muted },
		Special = { fg = p.cyan },
		SpecialChar = { fg = p.orange },
		SpecialKey = { fg = p.muted },
		SpellBad = { sp = p.red, undercurl = true },
		SpellCap = { sp = p.yellow, undercurl = true },
		SpellLocal = { sp = p.cyan, undercurl = true },
		SpellRare = { sp = p.magenta, undercurl = true },
		Statement = { fg = p.magenta },
		StatusLine = { fg = p.foreground, bg = p.lighter_background },
		StatusLineNC = { fg = p.light_foreground, bg = p.dark_background },
		StorageClass = { fg = p.yellow },
		String = { fg = p.green },
		Structure = { fg = p.yellow },
		Substitute = { fg = p.background, bg = p.magenta, bold = true },
		TabLine = { fg = p.light_foreground, bg = p.dark_background },
		TabLineFill = { bg = p.dark_background },
		TabLineSel = { fg = p.bright_foreground, bg = p.background, bold = true },
		Tag = { fg = p.blue },
		TelescopeBorder = { fg = p.muted, bg = p.lighter_background },
		TelescopeMatching = { fg = p.accent, bold = true },
		TelescopeNormal = { fg = p.foreground, bg = p.lighter_background },
		TelescopePromptBorder = { fg = p.selection, bg = p.selection },
		TelescopePromptNormal = { fg = p.foreground, bg = p.selection },
		TelescopePromptPrefix = { fg = p.accent, bg = p.selection },
		TelescopePromptTitle = { fg = p.background, bg = p.accent, bold = true },
		TelescopeResultsDiffAdd = { fg = p.green },
		TelescopeResultsDiffChange = { fg = p.yellow },
		TelescopeResultsDiffDelete = { fg = p.red },
		TelescopeSelection = { fg = p.foreground, bg = p.selection, underline = weak_selection or nil },
		TelescopeTitle = { fg = p.accent, bg = p.lighter_background, bold = true },
		Title = { fg = p.accent, bold = true },
		Todo = { fg = p.background, bg = p.yellow, bold = true },
		Type = { fg = p.yellow },
		Typedef = { fg = p.yellow },
		Underlined = { fg = p.blue, underline = true },
		VertSplit = { fg = p.muted },
		Visual = { fg = selection_fg, bg = selection_bg },
		VisualNOS = { fg = selection_fg, bg = selection_bg },
		WarningMsg = { fg = p.yellow, bold = true },
		WhichKey = { fg = p.accent, bold = true },
		WhichKeyDesc = { fg = p.foreground },
		WhichKeyFloat = { bg = p.lighter_background },
		WhichKeyGroup = { fg = p.cyan },
		WhichKeySeparator = { fg = p.muted },
		WhichKeyValue = { fg = p.light_foreground, italic = true },
		Whitespace = { fg = p.muted },
		WildMenu = { fg = p.bright_foreground, bg = p.selection, bold = true },
		WinBar = { fg = p.foreground, bg = p.background, bold = true },
		WinBarNC = { fg = p.light_foreground, bg = p.background },

		WinSeparator = { fg = p.muted },
		["@boolean"] = { link = "Boolean" },
		["@character"] = { link = "Character" },
		["@comment"] = { link = "Comment" },
		["@constant"] = { link = "Constant" },
		["@constant.builtin"] = { link = "Constant" },
		["@constructor"] = { fg = p.yellow },
		["@diff.delta"] = { fg = p.yellow },
		["@diff.minus"] = { fg = p.red },
		["@diff.plus"] = { fg = p.green },
		["@field"] = { fg = p.blue },
		["@float"] = { link = "Float" },
		["@function"] = { link = "Function" },
		["@function.builtin"] = { fg = p.cyan },
		["@function.call"] = { fg = p.blue },
		["@function.method"] = { fg = p.blue },
		["@function.method.call"] = { fg = p.blue },
		["@keyword"] = { link = "Keyword" },
		["@keyword.conditional"] = { fg = p.magenta },
		["@keyword.function"] = { fg = p.magenta },
		["@keyword.import"] = { fg = p.cyan },
		["@keyword.operator"] = { fg = p.cyan },
		["@keyword.repeat"] = { fg = p.magenta },
		["@keyword.return"] = { fg = p.magenta },
		["@markup.heading"] = { fg = p.accent, bold = true },
		["@markup.heading.1.delimiter.vimdoc"] = {
			fg = p.background,
			bg = p.background,
			sp = p.muted,
			underdouble = true,
			nocombine = true,
		},
		["@markup.heading.2.delimiter.vimdoc"] = {
			fg = p.background,
			bg = p.background,
			sp = p.muted,
			underline = true,
			nocombine = true,
		},
		["@markup.italic"] = { fg = p.foreground, italic = true },
		["@markup.link"] = { fg = p.blue, underline = true },
		["@markup.raw"] = { fg = p.green },
		["@markup.strong"] = { fg = p.bright_foreground, bold = true },
		["@number"] = { link = "Number" },
		["@operator"] = { link = "Operator" },
		["@property"] = { fg = p.blue },
		["@punctuation.bracket"] = { fg = p.foreground },
		["@punctuation.delimiter"] = { fg = p.muted },
		["@punctuation.special"] = { fg = p.cyan },
		["@string"] = { link = "String" },
		["@string.documentation"] = { fg = p.green, italic = true },
		["@string.escape"] = { fg = p.orange, bold = true },
		["@string.special"] = { fg = p.cyan },
		["@tag"] = { fg = p.blue },
		["@tag.attribute"] = { fg = p.yellow },
		["@tag.delimiter"] = { fg = p.muted },
		["@type"] = { link = "Type" },
		["@type.builtin"] = { link = "Type" },
		["@type.definition"] = { fg = p.yellow },
		["@variable"] = { fg = p.foreground },
		["@variable.builtin"] = { fg = p.red },
		["@variable.member"] = { fg = p.blue },
		["@variable.parameter"] = { fg = p.foreground, italic = true },
		markdownBold = { fg = p.bright_foreground, bold = true },
		markdownCode = { fg = p.green },
		markdownCodeBlock = { fg = p.green },
		markdownH1 = { fg = p.accent, bold = true },
		markdownH2 = { fg = p.blue, bold = true },
		markdownH3 = { fg = p.cyan, bold = true },
		markdownH4 = { fg = p.green, bold = true },
		markdownItalic = { fg = p.foreground, italic = true },
		markdownLinkText = { fg = p.blue, underline = true },
		typescriptAliasDeclaration = { link = "Type" },
		typescriptBraces = { link = "Delimiter" },
		typescriptEndColons = { link = "Delimiter" },
		typescriptInterfaceName = { link = "Type" },
		typescriptTypeParameter = { link = "Type" },
		typescriptTypeReference = { link = "Type" },
	}
	return highlights
end

return M
