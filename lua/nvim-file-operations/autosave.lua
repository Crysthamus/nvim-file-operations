---@class NvimFileOps.Autosave
local M = {}

---@type table<string, boolean>
local seen = {}

---@param uri string
---@param uris string[]
---@return string[] uris
local function add_uri(uri, uris)
  if uri and not seen[uri] then
    seen[uri] = true
    table.insert(uris, uri)
  end

  return uris
end

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
          vim.cmd.update({ mods = { silent = true } })
        end)
      end
    end
  end)
end

--- Parses an incoming LSP WorkspaceEdit structure and updates modified files
---@param workspace_edit? table The standard LSP WorkspaceEdit object payload
---@return string[] uris Array of unique URIs
local function extract_uris(workspace_edit)
  ---@type string[]
  local uris = {}
  seen = {}

  if not workspace_edit then
    return uris
  end

  if workspace_edit.changes then
    for uri, _ in pairs(workspace_edit.changes) do
      uris = add_uri(uri, uris)
    end
  end

  if workspace_edit.documentChanges then
    for _, change in ipairs(workspace_edit.documentChanges) do
      if type(change) == "table" and change.textDocument and change.textDocument.uri then
        uris = add_uri(change.textDocument.uri, uris)
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

    save_buffers(extract_uris(workspace_edit))

    return execution_result
  end
end

return M
