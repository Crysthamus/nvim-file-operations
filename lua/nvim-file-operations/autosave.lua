local M = {}

--- Safely writes a specific buffer to disk if it has unsaved mutations
---@param uris string[] List of URIs to process
local function save_buffers(uris)
  if #uris == 0 then
    return
  end

  vim.schedule(function()
    for _, uri in ipairs(uris) do
      local bufnr = vim.uri_to_bufnr(uri)

      if
        bufnr
        and vim.api.nvim_buf_is_loaded(bufnr)
        and vim.api.nvim_buf_is_valid(bufnr)
        and vim.bo[bufnr].modified
      then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("silent! update")
        end)
      end
    end
  end)
end

--- Parses an incoming LSP WorkspaceEdit structure and updates modified files
---@param workspace_edit table? The standard LSP WorkspaceEdit object payload
---@return string[] uris Array of unique URIs
local function extract_uris(workspace_edit)
  local uris = {}
  local seen = {}

  if not workspace_edit then
    return uris
  end

  local function add_uri(uri)
    if uri and not seen[uri] then
      seen[uri] = true
      table.insert(uris, uri)
    end
  end

  if workspace_edit.changes then
    for uri, _ in pairs(workspace_edit.changes) do
      add_uri(uri)
    end
  end

  if workspace_edit.documentChanges then
    for _, change in ipairs(workspace_edit.documentChanges) do
      if type(change) == "table" and change.textDocument and change.textDocument.uri then
        add_uri(change.textDocument.uri)
      end
    end
  end

  return uris
end

--- Configures a deferred interceptor hook targeting Neovim's workspace edit application
function M.setup()
  local original_apply_workspace_edit = vim.lsp.util.apply_workspace_edit

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.util.apply_workspace_edit = function(workspace_edit, offset_encoding, ...)
    local execution_result = original_apply_workspace_edit(workspace_edit, offset_encoding, ...)

    local uris = extract_uris(workspace_edit)
    save_buffers(uris)

    return execution_result
  end
end

return M
