---@class LspOps
local M = {}

--- Validates file patterns against LSP glob filters
---@param filters? table
---@param fname string
---@return boolean matches
local function matches_filters(filters, fname)
  if not filters or #filters == 0 then
    return true
  end

  for _, filter in ipairs(filters) do
    local glob = filter.pattern and filter.pattern.glob
    if glob then
      local ok, lpeg = pcall(vim.glob.to_lpeg, glob)
      if ok and lpeg:match(fname) then
        return true
      end
    end
  end
  return false
end

---@param data { old_name: string, new_name: string }
---@return table
local function rename_params(data)
  return {
    files = {
      {
        oldUri = vim.uri_from_fname(data.old_name),
        newUri = vim.uri_from_fname(data.new_name),
      },
    },
  }
end

---@param data { fname: string }
---@return table
local function create_or_delete_params(data)
  return {
    files = { { uri = vim.uri_from_fname(data.fname) } },
  }
end

---@param capability string LSP file operation name (eg. `didCreate`, `willCreate`)
---@param method string LSP method identifier (eg. `workspace/didCreateFiles`)
---@param build_params fun(data: table): table Constructs the LSP request/notification params
---@param use_request boolean Whether to use request_sync instead of notify
---@return fun(data: table) Handler that dispatches the operation to matching LSP clients
local function make_handler(capability, method, build_params, use_request)
  local config = require("nvim-file-operations.config")

  return function(data)
    for _, client in ipairs(vim.lsp.get_clients({ method = method })) do
      local cap =
        vim.tbl_get(client, "server_capabilities", "workspace", "fileOperations", capability)

      if cap and matches_filters(cap.filters, data.old_name or data.fname) then
        local params = build_params(data)

        if use_request then
          local ok, res = pcall(function()
            return client:request_sync(method, params, config.options.timeout_ms)
          end)

          if not ok then
            vim.notify(
              string.format("[LSP] Exception in %s: %s", method, tostring(res)),
              vim.log.levels.ERROR
            )
          elseif res and res.result then
            vim.lsp.util.apply_workspace_edit(res.result, client.offset_encoding)
          elseif res and res.err then
            vim.notify(
              string.format("[LSP] Server error in %s: %s", method, vim.inspect(res.err)),
              vim.log.levels.WARN
            )
          end
        else
          client:notify(method, params)
        end
      end
    end
  end
end

M.did_create = make_handler("didCreate", "workspace/didCreateFiles", create_or_delete_params, false)
M.did_delete = make_handler("didDelete", "workspace/didDeleteFiles", create_or_delete_params, false)
M.did_rename = make_handler("didRename", "workspace/didRenameFiles", rename_params, false)

M.will_create =
  make_handler("willCreate", "workspace/willCreateFiles", create_or_delete_params, true)
M.will_delete =
  make_handler("willDelete", "workspace/willDeleteFiles", create_or_delete_params, true)
M.will_rename = make_handler("willRename", "workspace/willRenameFiles", rename_params, true)

return M
