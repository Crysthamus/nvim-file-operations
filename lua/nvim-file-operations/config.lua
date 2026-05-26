local M = {}

---@class Options
---@field auto_save? boolean
---@field timeout_ms? number
---@field did_create_files? boolean
---@field did_delete_files? boolean
---@field did_rename_files? boolean
---@field will_create_files? boolean
---@field will_delete_files? boolean
---@field will_rename_files? boolean

---@type Options
local defaults = {
  auto_save = false,
  timeout_ms = 10000,
  did_create_files = true,
  did_delete_files = true,
  did_rename_files = true,
  will_create_files = true,
  will_delete_files = true,
  will_rename_files = true,
}

local capabilities = {
  will_rename_files = "willRename",
  did_rename_files = "didRename",
  will_create_files = "willCreate",
  did_create_files = "didCreate",
  will_delete_files = "willDelete",
  did_delete_files = "didDelete",
}

M.options = {}

---@param opts Options?
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", defaults, opts or {})
end

M.default_capabilities = function()
  local config = next(M.options) == nil and defaults or M.options

  local result = {
    workspace = {
      fileOperations = {},
    },
  }

  for operation, capability in pairs(capabilities) do
    result.workspace.fileOperations[capability] = config[operation]
  end

  return result
end

return M
