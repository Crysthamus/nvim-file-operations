---@class NvimFileOps.Config
local M = {}

---@class NvimFileOps.Options
---@field auto_save? boolean
---@field timeout_ms? number
---@field did_create_files? boolean
---@field did_delete_files? boolean
---@field did_rename_files? boolean
---@field will_create_files? boolean
---@field will_delete_files? boolean
---@field will_rename_files? boolean
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

---@enum NvimFileOps.Capabilities
local capabilities = {
  will_rename_files = "willRename",
  did_rename_files = "didRename",
  will_create_files = "willCreate",
  did_create_files = "didCreate",
  will_delete_files = "willDelete",
  did_delete_files = "didDelete",
}

---@type NvimFileOps.Options
M.options = {}

---@param opts? NvimFileOps.Options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", defaults, opts or {})
end

---@return lsp.ServerCapabilities result
function M.default_capabilities()
  local config = vim.tbl_isempty(M.options) and defaults or M.options

  ---@type lsp.ServerCapabilities
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
