---@class LspOps.DidRename
local M = {}

local DID_RENAME_PATH = { "server_capabilities", "workspace", "fileOperations", "didRename" }

function M.callback(data)
  local utils = require("lsp-operations.utils")
  local params = {
    files = {
      {
        oldUri = vim.uri_from_fname(data.old_name),
        newUri = vim.uri_from_fname(data.new_name),
      },
    },
  }

  for _, client in ipairs(utils.get_clients()) do
    local did_rename = utils.get_nested_path(client, DID_RENAME_PATH)

    if did_rename and utils.matches_filters(did_rename.filters, data.old_name) then
      client:notify("workspace/didRenameFiles", params)
    end
  end
end

return M
