local send
local list_uis
local notify

---Simulate terminal responses for a palette.
---@param colors table
local function respond(colors)
	for index = 15, 0, -1 do
		local color = colors[index]
		require("chameleon.terminal").receive(
			string.format("\027]4;%d;rgb:%s/%s/%s", index, color:sub(2, 3), color:sub(4, 5), color:sub(6, 7))
		)
	end
	for index, key in ipairs({ "foreground", "background" }) do
		local color = colors[key]
		if color then
			require("chameleon.terminal").receive(
				string.format("\027]%d;rgb:%s/%s/%s", index + 9, color:sub(2, 3), color:sub(4, 5), color:sub(6, 7))
			)
		end
	end
end

return {
	---Save editor state and prepare terminal mocks.
	before = function()
		local terminal = require("chameleon.terminal")
		terminal.cancel()
		terminal.colors = nil
		send = vim.api.nvim_ui_send
		---Suppress terminal queries during the test.
		vim.api.nvim_ui_send = function() end
		list_uis = vim.api.nvim_list_uis
		notify = vim.notify
		---Simulate the attached terminal UI state.
		vim.api.nvim_list_uis = function()
			return { { stdout_tty = true } }
		end
	end,

	---Cancel pending queries and restore editor state.
	after = function()
		require("chameleon.terminal").cancel()
		vim.api.nvim_ui_send = send
		vim.api.nvim_list_uis = list_uis
		vim.notify = notify
	end,

	---Verify: Terminal RGB responses support one to four hex digits per channel.
	["Terminal RGB responses support one to four hex digits per channel"] = function()
		-- Given
		local responses = {
			{ "\027]4;1;rgb:f/8/0", 1, "#ff8800" },
			{ "\027]4;15;rgb:ff/88/00\027\\", 15, "#ff8800" },
			{ "\027]10;rgb:fff/888/000\007", "foreground", "#ff8800" },
			{ "\027]11;rgb:ffff/8888/0000", "background", "#ff8800" },
			{ "\027]4;0;rgb:8000/0000/ffff", 0, "#8000ff" },
		}

		for _, response in ipairs(responses) do
			-- When
			local key, color = require("chameleon.terminal").parse_response(response[1])

			-- Then
			assert(key == response[2], "got:" .. tostring(key))
			assert(color == response[3], "got:" .. tostring(color))
		end
	end,

	---Verify: Unrelated and malformed terminal responses are ignored.
	["Unrelated and malformed terminal responses are ignored"] = function()
		-- Given
		local responses = {
			"\027P>|Rex",
			"\027]4;16;rgb:ff/ff/ff",
			"\027]4;1;rgb:fffff/ff/ff",
			"\027]4;1;rgb:zz/ff/ff",
			"\027]4;1;rgb:ff/ff/ff;text",
			"\027]4;invalid",
			"\027]12;rgb:ff/ff/ff",
		}

		for _, response in ipairs(responses) do
			-- When
			local key = require("chameleon.terminal").parse_response(response)

			-- Then
			assert(key == nil, "Accepted malformed response: " .. response)
		end
	end,

	---Verify: All ANSI colors and the default colors are queried without overlapping requests.
	["All ANSI colors and the default colors are queried without overlapping requests"] = function()
		-- Given
		local requests = {}
		---Record terminal queries sent by the plugin.
		vim.api.nvim_ui_send = function(query)
			table.insert(requests, query)
		end

		-- When
		---Start a query with a no-op completion callback.
		require("chameleon.terminal").query(function() end)
		---Start a query with a no-op completion callback.
		require("chameleon.terminal").query(function() end)

		-- Then
		assert(
			---Check whether the asynchronous operation has completed.
			vim.wait(500, function()
				return #requests == 1
			end),
			"Palette query was not sent"
		)
		assert(#requests == 1, "Overlapping requests were sent")
		for index = 0, 15 do
			assert(requests[1]:find(string.format("\027]4;%d;?\027\\", index), 1, true))
		end
		assert(requests[1]:find("\027]10;?\027\\\027]11;?\027\\", 1, true))
	end,

	---Verify: A complete palette is applied once even when responses arrive out of order.
	["A complete palette is applied once even when responses arrive out of order"] = function()
		-- Given
		local got
		local count = 0
		---Capture completion of the terminal palette query.
		require("chameleon.terminal").query(function(colors)
			got = colors
			count = count + 1
		end)

		-- When
		respond(require("tests.current.colors"))
		respond(require("tests.current.colors"))

		-- Then
		assert(vim.deep_equal(got, require("tests.current.colors")))
		assert(count == 1)
	end,

	---Verify: The previous palette is kept until every ANSI color has arrived.
	["The previous palette is kept until every ANSI color has arrived"] = function()
		-- Given
		local terminal = require("chameleon.terminal")
		terminal.colors = vim.deepcopy(require("tests.current.colors"))
		local previous = vim.deepcopy(terminal.colors)
		---Capture completion of the terminal palette query.
		terminal.query(function()
			error("Incomplete palette was applied")
		end)

		-- When
		terminal.receive("\027]4;0;rgb:ff/ff/ff")

		-- Then
		assert(vim.deep_equal(terminal.colors, previous))
	end,

	---Verify: Loading the colorscheme again can apply the same palette.
	["Loading the colorscheme again can apply the same palette"] = function()
		-- Given
		local terminal = require("chameleon.terminal")
		terminal.colors = vim.deepcopy(require("tests.current.colors"))
		local applied = false
		---Capture completion of the terminal palette query.
		terminal.query(function()
			applied = true
		end)

		-- When
		respond(require("tests.current.colors"))

		-- Then
		assert(vim.deep_equal(terminal.colors, require("tests.current.colors")))
		assert(applied)
	end,

	---Verify: Terminals without default color responses still supply a palette.
	["Terminals without default color responses still supply a palette"] = function()
		-- Given
		local colors = vim.deepcopy(require("tests.current.colors"))
		colors.foreground = nil
		colors.background = nil
		local got
		---Capture completion of the terminal palette query.
		require("chameleon.terminal").query(function(result)
			got = result
		end)

		-- When
		respond(colors)
		assert(
			---Check whether the asynchronous operation has completed.
			vim.wait(1500, function()
				return got ~= nil
			end),
			"Palette query did not finish"
		)

		-- Then
		assert(vim.deep_equal(got, colors))
	end,

	---Verify: Cancelled requests ignore late responses.
	["Cancelled requests ignore late responses"] = function()
		-- Given
		local terminal = require("chameleon.terminal")
		---Capture completion of the terminal palette query.
		terminal.query(function()
			error("Cancelled request was applied")
		end)

		-- When
		terminal.cancel()
		respond(require("tests.current.colors"))

		-- Then
		assert(terminal.colors == nil)
	end,

	---Verify: Incomplete queries keep the previous palette and clean up their listeners.
	["Incomplete queries keep the previous palette and clean up their listeners"] = function()
		-- Given
		local terminal = require("chameleon.terminal")
		local previous = vim.deepcopy(require("tests.current.colors"))
		terminal.colors = previous
		local warning
		---Capture notifications for assertions.
		vim.notify = function(message)
			warning = message
		end
		---Capture completion of the terminal palette query.
		terminal.query(function()
			error("Incomplete palette was applied")
		end)

		-- When
		terminal.receive("\027]4;1;rgb:ff/ff/ff")
		assert(
			---Check whether the asynchronous operation has completed.
			vim.wait(1500, function()
				return warning ~= nil
			end),
			"Missing palette warning was not shown"
		)

		-- Then
		assert(terminal.colors == previous)
		assert(#vim.api.nvim_get_autocmds({ group = "chameleon-query" }) == 0)
	end,
}
