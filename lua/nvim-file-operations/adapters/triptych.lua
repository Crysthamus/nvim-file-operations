---@class NvimFileOps.Adapters.Triptych
local M = {}

function M.setup()
  local ok_triptych = pcall(require, "triptych")
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

  require("nvim-file-operations.events").bind_adapters(events, function(handler_module, file_event)
    vim.api.nvim_create_autocmd("User", {
      pattern = file_event,
      desc = "nvim-file-operations triptych adapter",
      callback = function(event)
        if not event.data then
          return
        end

        local payload = (event.data.from_path and event.data.to_path)
            and { old_name = event.data.from_path, new_name = event.data.to_path }
          or (event.data.path and { fname = event.data.path } or nil)

        if payload then
          require(handler_module).callback(payload)
        end
      end,
    })
  end)
end

return M
