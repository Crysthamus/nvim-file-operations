---@class LspOps.WillRename
local M = {}

local WILL_RENAME_PATH = { "server_capabilities", "workspace", "fileOperations", "willRename" }

---@param data { old_name: string, new_name: string }
function M.callback(data)
  local utils = require("lsp-operations.utils")
  local config = require("nvim-file-operations.config")
  local params = {
    files = {
      {
        oldUri = vim.uri_from_fname(data.old_name),
        newUri = vim.uri_from_fname(data.new_name),
      },
    },
  }

  for _, client in ipairs(utils.get_clients()) do
    local will_rename = utils.get_nested_path(client, WILL_RENAME_PATH)

    if will_rename and utils.matches_filters(will_rename.filters, data.old_name) then
      local success, response = pcall(function()
        return client:request_sync("workspace/willRenameFiles", params, config.options.timeout_ms)
      end)

      if success and response and response.result then
        vim.lsp.util.apply_workspace_edit(response.result, client.offset_encoding)
      end
    end
  end
end

return M
