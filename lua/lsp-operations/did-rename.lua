local utils = require("lsp-operations.utils")
local M = {}

local DID_RENAME_PATH = { "server_capabilities", "workspace", "fileOperations", "didRename" }

M.callback = function(data)
  local params = {
    files = {
      {
        oldUri = vim.uri_from_fname(data.old_name),
        newUri = vim.uri_from_fname(data.new_name),
      },
    },
  }

  local clients = utils.get_clients()
  for i = 1, #clients do
    local client = clients[i]
    local did_rename = utils.get_nested_path(client, DID_RENAME_PATH)

    if did_rename and utils.matches_filters(did_rename.filters, data.old_name) then
      client.notify("workspace/didCreateFiles", params)
    end
  end
end

return M
