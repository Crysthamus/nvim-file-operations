---@class NvimFileOps.Events
local M = {}

---@enum NvimFileOps.InternalHandlers
local internal_handlers = {
  did_create_files = { "lsp-operations", "did_create" },
  did_delete_files = { "lsp-operations", "did_delete" },
  did_rename_files = { "lsp-operations", "did_rename" },
  will_create_files = { "lsp-operations", "will_create" },
  will_delete_files = { "lsp-operations", "will_delete" },
  will_rename_files = { "lsp-operations", "will_rename" },
}

--- Binds third-party tree plugin events to your internal operation handlers.
---@param plugin_events table Map of snake_case operations to tree plugin event names
---@param adapter_bind_fn fun(module: string, fn_name: string, tree_event: string)
function M.bind_adapters(plugin_events, adapter_bind_fn)
  local config = require("nvim-file-operations.config")

  for config_key, handler in pairs(internal_handlers) do
    if config.options[config_key] and plugin_events[config_key] then
      for _, event in ipairs(plugin_events[config_key]) do
        adapter_bind_fn(handler[1], handler[2], event)
      end
    end
  end
end

return M
