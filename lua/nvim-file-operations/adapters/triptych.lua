local M = {}

M.setup = function()
	local events_engine = require("nvim-file-operations.events")
	local ok_triptych, _ = pcall(require, "triptych")
	if not ok_triptych then
		return
	end

	local events = {
		will_rename_files = { "TriptychWillMoveNode" },
		did_rename_files = { "TriptychDidMoveNode" },
		will_create_files = { "TriptychWillCreateNode" },
		did_create_files = { "TriptychDidCreateNode" },
		will_delete_files = { "TriptychWillDeleteNode" },
		did_delete_files = { "TriptychDidDeleteNode" },
	}

	events_engine.bind_adapters(events, function(handler_module, file_event)
		vim.api.nvim_create_autocmd("User", {
			pattern = file_event,
			desc = "nvim-file-operations triptych adapter",
			callback = function(event)
				local data = event.data
				if not data then
					return
				end

				local payload = nil

				if data.from_path and data.to_path then
					payload = { old_name = data.from_path, new_name = data.to_path }
				elseif data.path then
					payload = { fname = data.path }
				end

				if payload then
					require(handler_module).callback(payload)
				end
			end,
		})
	end)
end

return M
