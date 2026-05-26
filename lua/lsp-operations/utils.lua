local M = {}

local regex_cache = {}

--- Safely and rapidly traverse nested tables
---@param obj table
---@param path string[]
---@return any|nil
M.get_nested_path = function(obj, path)
	local current = obj
	for i = 1, #path do
		if type(current) ~= "table" then
			return nil
		end
		current = current[path[i]]
	end
	return current
end

--- Validates file patterns using Neovim's internal C-regex engine
---@param filters table|nil
---@param fname string
---@return boolean
M.matches_filters = function(filters, fname)
	if not filters or #filters == 0 then
		return true
	end

	for i = 1, #filters do
		local glob = filters[i].pattern and filters[i].pattern.glob
		if glob then
			local regex = regex_cache[glob]

			if not regex then
				local regpat = vim.fn.glob2regpat(glob)
				regex = vim.regex(regpat)
				regex_cache[glob] = regex
			end

			if regex:match_str(fname) then
				return true
			end
		end
	end
	return false
end

M.get_clients = vim.lsp.get_clients

return M
