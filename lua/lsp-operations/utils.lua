---@class LspOps.Utils
local M = {}

local regex_cache = {}

--- Safely and rapidly traverse nested tables
---@param obj table
---@param path string[]
---@return any current
function M.get_nested_path(obj, path)
  local current = obj
  for _, value in ipairs(path) do
    if type(current) ~= "table" then
      return nil
    end
    current = current[value]
  end
  return current
end

--- Validates file patterns using Neovim's internal C-regex engine
---@param filters? table
---@param fname string
---@return boolean matches
function M.matches_filters(filters, fname)
  if not filters or #filters == 0 then
    return true
  end

  for _, filter in ipairs(filters) do
    local glob = filter.pattern and filter.pattern.glob
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
