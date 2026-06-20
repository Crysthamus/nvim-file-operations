---@class LspOps.DidCreate
local M = {}

local DID_CREATE_PATH = { "server_capabilities", "workspace", "fileOperations", "didCreate" }

function M.callback(data)
  local utils = require("lsp-operations.utils")
  local params = {
    files = { { uri = vim.uri_from_fname(data.fname) } },
  }

  for _, client in ipairs(utils.get_clients()) do
    local did_create = utils.get_nested_path(client, DID_CREATE_PATH)

    if did_create and utils.matches_filters(did_create.filters, data.fname) then
      client:notify("workspace/didCreateFiles", params)
    end
  end
end

return M
