---@class NvimFileOps.Autosave
local M = {}

---@type boolean
local in_apply = false

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
        vim.api.nvim_buf_is_valid(bufnr)
        and vim.api.nvim_buf_is_loaded(bufnr)
        and vim.bo[bufnr].modified
      then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd.update({ mods = { silent = true } })
        end)
      end
    end
  end)
end

--- Parses an incoming LSP WorkspaceEdit structure and extracts modified files
---@param workspace_edit? table The standard LSP WorkspaceEdit object payload
---@return string[] uris Array of unique URIs
local function extract_uris(workspace_edit)
  ---@type string[]
  local uris = {}

  if not workspace_edit then
    return uris
  end

  local seen = {}

  if workspace_edit.changes then
    for uri, _ in pairs(workspace_edit.changes) do
      if not seen[uri] then
        seen[uri] = true
        uris[#uris + 1] = uri
      end
    end
  end

  if workspace_edit.documentChanges then
    for _, change in ipairs(workspace_edit.documentChanges) do
      if type(change) == "table" and change.textDocument and change.textDocument.uri then
        local uri = change.textDocument.uri
        if not seen[uri] then
          seen[uri] = true
          uris[#uris + 1] = uri
        end
      end
    end
  end

  return uris
end

--- Configures a deferred interceptor hook targeting Neovim's workspace edit application
function M.setup()
  local original_apply_workspace_edit = vim.lsp.util.apply_workspace_edit

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.util.apply_workspace_edit = function(workspace_edit, position_encoding, ...)
    if in_apply then
      return original_apply_workspace_edit(workspace_edit, position_encoding, ...)
    end

    in_apply = true
    local ok, result = pcall(original_apply_workspace_edit, workspace_edit, position_encoding, ...)
    in_apply = false

    if ok then
      save_buffers(extract_uris(workspace_edit))
      return result
    else
      vim.notify("LSP apply_workspace_edit failed: " .. tostring(result), vim.log.levels.ERROR)
    end
  end
end

return M
