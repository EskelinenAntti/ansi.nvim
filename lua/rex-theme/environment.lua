local M = {}

M.is_rex = function()
	return vim.env.TERM_PROGRAM == "rex"
end

return M
