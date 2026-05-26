local utils = require("lsp-operations.utils")
local config = require("nvim-file-operations.config")
local M = {}

local WILL_CREATE_PATH = { "server_capabilities", "workspace", "fileOperations", "willCreate" }

M.callback = function(data)
  local params = {
    files = { { uri = vim.uri_from_fname(data.fname) } },
  }

  local clients = utils.get_clients()
  for i = 1, #clients do
    local client = clients[i]
    local will_create = utils.get_nested_path(client, WILL_CREATE_PATH)

    if will_create and utils.matches_filters(will_create.filters, data.fname) then
      local success, response = pcall(function()
        return client:request_sync("workspace/willCreateFiles", params, config.options.timeout_ms)
      end)

      if success and response and response.result then
        vim.lsp.util.apply_workspace_edit(response.result, client.offset_encoding)
      end
    end
  end
end

return M
