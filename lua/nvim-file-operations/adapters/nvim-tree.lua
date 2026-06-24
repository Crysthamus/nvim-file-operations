---@class NvimFileOps.Adapters.NvimTree
local M = {}

function M.setup()
  local ok_nvim_tree, nvim_tree_api = pcall(require, "nvim-tree.api")
  if not (ok_nvim_tree and nvim_tree_api) then
    return
  end

  local nvim_tree_events = nvim_tree_api.events.Event
  local events = {
    will_rename_files = { nvim_tree_events.WillRenameNode },
    did_rename_files = { nvim_tree_events.NodeRenamed },
    did_create_files = { nvim_tree_events.FileCreated },
    did_delete_files = { nvim_tree_events.FileRemoved },
  }

  require("nvim-file-operations.events").bind_adapters(events, function(handler_module, tree_event)
    nvim_tree_api.events.subscribe(tree_event, function(args)
      require(handler_module).callback(args)
    end)
  end)
end

return M
