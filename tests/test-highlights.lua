local snapshot_path = "tests/snapshots/highlights.txt"

---Serialize the current palette’s highlight definitions.
---@return string
local function snapshot()
	local palette = require("chameleon.palette").palette_for(require("tests.current.colors"))
	local highlights = require("chameleon.highlighter").highlights_for(palette)
	return vim.inspect(highlights, { sort_keys = true }) .. "\n"
end

---Compare a snapshot with its fixture, or update it when requested.
---@param path string
---@param snapshot fun(): string
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
	---Verify: Highlight definitions match the snapshot.
	["Highlight definitions match the snapshot"] = function()
		assert_snapshot(snapshot_path, snapshot)
	end,
}
