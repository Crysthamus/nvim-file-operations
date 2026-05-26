local M = {}
local config = require("nvim-file-operations.config")

local internal_handlers = {
	did_create_files = "lsp-operations.did-create",
	did_delete_files = "lsp-operations.did-delete",
	did_rename_files = "lsp-operations.did-rename",
	will_create_files = "lsp-operations.will-create",
	will_delete_files = "lsp-operations.will-delete",
	will_rename_files = "lsp-operations.will-rename",
}

--- Binds third-party tree plugin events to your internal operation handlers.
---@param plugin_events table Map of snake_case operations to tree plugin event names
---@param adapter_bind_fn fun(handler_module: string, tree_event: string)
M.bind_adapters = function(plugin_events, adapter_bind_fn)
	for config_key, handler_module in pairs(internal_handlers) do
		if config.options[config_key] then
			local tree_events = plugin_events[config_key]

			if tree_events then
				for i = 1, #tree_events do
					adapter_bind_fn(handler_module, tree_events[i])
				end
			end
		end
	end
end

return M
