local M = {}

M.setup = function()
	local events_engine = require("nvim-file-operations.events")
	local ok_neo_tree, neo_tree_events = pcall(require, "neo-tree.events")
	if not ok_neo_tree then
		return
	end

	local events = {
		will_rename_files = { neo_tree_events.BEFORE_FILE_RENAME, neo_tree_events.BEFORE_FILE_MOVE },
		will_delete_files = { neo_tree_events.BEFORE_FILE_DELETE },
		will_create_files = { neo_tree_events.BEFORE_FILE_ADD },
		did_rename_files = { neo_tree_events.FILE_RENAMED, neo_tree_events.FILE_MOVED },
		did_create_files = { neo_tree_events.FILE_ADDED },
		did_delete_files = { neo_tree_events.FILE_DELETED },
	}

	events_engine.bind_adapters(events, function(handler_module, tree_event)
		local id = ("%s.%s"):format(handler_module, tree_event)
		neo_tree_events.unsubscribe({ id = id })
		neo_tree_events.subscribe({
			id = id,
			event = tree_event,
			handler = function(args)
				if type(args) == "table" then
					args = { old_name = args.source, new_name = args.destination }
				else
					args = { fname = args }
				end
				require(handler_module).callback(args)
			end,
		})
	end)
end

return M
