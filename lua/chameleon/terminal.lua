local M = {}

---@type table|nil
M.colors = nil

local pending
local timeout
local group = vim.api.nvim_create_augroup("chameleon-query", { clear = true })

---Parse a terminal color response. Neovim strips the string terminator from TermResponse events.
---@param sequence string
---@return number|string|nil key ANSI index, "foreground", or "background"
---@return string|nil color
function M.parse_response(sequence)
	sequence = sequence:gsub("\027\\$", ""):gsub("\007$", "")
	local command, value = sequence:match("^\027%](%d+);(.*)$")
	local key
	if command == "4" then
		local index
		index, value = value:match("^(%d+);(.*)$")
		key = tonumber(index)
		if not key or key > 15 then
			return
		end
	elseif command == "10" then
		key = "foreground"
	elseif command == "11" then
		key = "background"
	else
		return
	end

	local r, g, b = value:match("^rgb:([%x]+)/([%x]+)/([%x]+)$")
	if not r or #r > 4 or #g > 4 or #b > 4 then
		return
	end

	local function channel(hex)
		return math.floor(tonumber(hex, 16) * 255 / (16 ^ #hex - 1) + 0.5)
	end

	return key, string.format("#%02x%02x%02x", channel(r), channel(g), channel(b))
end

function M.cancel()
	pending = nil
	vim.api.nvim_clear_autocmds({ group = group })
	if timeout then
		if not timeout:is_closing() then
			timeout:stop()
			timeout:close()
		end
		timeout = nil
	end
end

local function finish()
	local request = pending
	M.cancel()
	if not request then
		return
	end

	for index = 0, 15 do
		if not request.colors[index] then
			vim.notify("Could not read theme colors from the terminal.", vim.log.levels.WARN)
			return
		end
	end

	M.colors = request.colors
	request.callback(M.colors)
end

---@param sequence string
function M.receive(sequence)
	if not pending then
		return
	end
	local key, color = M.parse_response(sequence)
	if key == nil then
		return
	end
	pending.colors[key] = color

	for index = 0, 15 do
		if not pending.colors[index] then
			return
		end
	end
	if pending.colors.foreground and pending.colors.background then
		finish()
	end
end

---Query the terminal without blocking Neovim. Keep the previous palette until a full ANSI palette arrives.
---@param callback fun(colors: table)
function M.query(callback)
	if pending then
		return
	end
	pending = { colors = {}, callback = callback }
	local request = pending
	vim.api.nvim_create_autocmd("TermResponse", {
		group = group,
		callback = function(event)
			M.receive(event.data.sequence)
		end,
	})
	vim.api.nvim_create_autocmd({ "ColorSchemePre", "VimLeavePre" }, { group = group, callback = M.cancel })

	local queries = {}
	for index = 0, 15 do
		table.insert(queries, string.format("\027]4;%d;?\027\\", index))
	end
	table.insert(queries, "\027]10;?\027\\\027]11;?\027\\")

	local function send()
		if pending ~= request then
			return
		end
		-- Allow optional OSC 10/11 responses time to arrive before falling back to ANSI defaults.
		timeout = vim.defer_fn(function()
			if pending == request then
				finish()
			end
		end, 1000)
		vim.api.nvim_ui_send(table.concat(queries))
	end

	if #vim.api.nvim_list_uis() == 0 then
		-- The colorscheme can be loaded from init.lua before the TUI attaches.
		vim.api.nvim_create_autocmd("UIEnter", { group = group, once = true, callback = send })
	else
		send()
	end
end

return M
