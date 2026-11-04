local snapshot_path = "tests/snapshots/highlights.txt"

local function snapshot()
	local palette = require("ansi.palette").palette_for(require("tests.current.colors"))
	local highlights = require("ansi.highlighter").highlights_for(palette)
	return vim.inspect(highlights, { sort_keys = true }) .. "\n"
end

local function assert_snapshot(path, snapshot)
	local got = snapshot()
	if vim.env.UPDATE_SNAPSHOTS == "1" then
		local file = assert(io.open(path, "w"))
		file:write(got)
		file:close()
		return
	end

	local file = assert(io.open(path, "r"))
	local want = file:read("*a")
	file:close()

	assert(got == want, "highlight snapshot differs\n\nExpected:\n" .. want .. "\nGot:\n" .. got)
end

return {
	["Highlight definitions match the snapshot"] = function()
		assert_snapshot(snapshot_path, snapshot)
	end,
}
