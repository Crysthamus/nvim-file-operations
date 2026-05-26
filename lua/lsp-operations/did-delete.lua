local utils = require("lsp-operations.utils")
local M = {}

local DID_DELETE_PATH = { "server_capabilities", "workspace", "fileOperations", "didDelete" }

M.callback = function(data)
  local params = {
    files = { { uri = vim.uri_from_fname(data.fname) } },
  }

  local clients = utils.get_clients()
  for i = 1, #clients do
    local client = clients[i]
    local did_delete = utils.get_nested_path(client, DID_DELETE_PATH)

    if did_delete and utils.matches_filters(did_delete.filters, data.fname) then
      client:notify("workspace/didDeleteFiles", params)
    end
  end
end

return M
