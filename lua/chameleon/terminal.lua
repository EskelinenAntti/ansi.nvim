local group = vim.api.nvim_create_augroup("chameleon-query", {})

local function parse(sequence)
	local prefix, r, g, b = sequence:match("^\027%]([%d;]+);rgb:([%x]+)/([%x]+)/([%x]+)$")
	if not prefix or #r > 4 or #g > 4 or #b > 4 then
		return
	end
	local key = prefix == "10" and "foreground"
		or prefix == "11" and "background"
		or tonumber(prefix:match("^4;(%d+)$"))
	if not key or (type(key) == "number" and key > 15) then
		return
	end
	local function channel(hex)
		return math.floor(tonumber(hex, 16) * 255 / (16 ^ #hex - 1) + 0.5)
	end
	return key, string.format("#%02x%02x%02x", channel(r), channel(g), channel(b))
end

return function(callback)
	local colors, count = {}, 0
	local timer, done
	local function stop()
		done = true
		vim.api.nvim_clear_autocmds({ group = group })
		if timer and not timer:is_closing() then
			timer:close()
		end
	end
	local function finish()
		if done then
			return
		end
		stop()
		for i = 0, 15 do
			if not colors[i] then
				vim.notify("Could not read theme colors from the terminal.", vim.log.levels.WARN)
				return
			end
		end
		callback(colors)
	end
	vim.api.nvim_create_autocmd("TermResponse", {
		group = group,
		callback = function(event)
			local key, color = parse(event.data.sequence)
			if key == nil then
				return
			end
			count = count + (colors[key] and 0 or 1)
			colors[key] = color
			if count == 18 then
				finish()
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "ColorSchemePre", "VimLeavePre" }, { group = group, callback = stop })
	local function send()
		-- Wait for optional OSC 10/11 replies before falling back to ANSI 7/0.
		timer = vim.defer_fn(finish, 1000)
		local queries = {}
		for i = 0, 15 do
			queries[#queries + 1] = string.format("\027]4;%d;?\027\\", i)
		end
		vim.api.nvim_ui_send(table.concat(queries) .. "\027]10;?\027\\\027]11;?\027\\")
	end
	if #vim.api.nvim_list_uis() == 0 then
		vim.api.nvim_create_autocmd("UIEnter", { group = group, once = true, callback = send })
	else
		send()
	end
end
