local M = {}

--- Safely writes a specific buffer to disk if it has unsaved mutations
---@param uri string The URI format string of the targeted document
local function save_buffer_by_uri(uri)
  local bufnr = vim.uri_to_bufnr(uri)
  if bufnr then
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("silent! update")
        end)
      end
    end)
  end
end

--- Parses an incoming LSP WorkspaceEdit structure and updates modified files
---@param workspace_edit table? The standard LSP WorkspaceEdit object payload
local function process_workspace_autosave(workspace_edit)
  if not workspace_edit then
    return
  end

  if workspace_edit.changes then
    for uri, _ in pairs(workspace_edit.changes) do
      save_buffer_by_uri(uri)
    end
  end

  if workspace_edit.documentChanges then
    local total_changes = #workspace_edit.documentChanges
    for i = 1, total_changes do
      local change = workspace_edit.documentChanges[i]
      if change and change.textDocument and change.textDocument.uri then
        save_buffer_by_uri(change.textDocument.uri)
      end
    end
  end
end

--- Configures a deferred interceptor hook targeting Neovim's workspace edit application
function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    once = true,
    callback = function()
      local original_apply_workspace_edit = vim.lsp.util.apply_workspace_edit
      local auto_save_enabled = nil

      ---@diagnostic disable-next-line: duplicate-set-field
      vim.lsp.util.apply_workspace_edit = function(workspace_edit, offset_encoding)
        local execution_result = original_apply_workspace_edit(workspace_edit, offset_encoding)

        if auto_save_enabled == nil then
          local ok, config = pcall(require, "nvim-file-operations.config")
          auto_save_enabled = ok and config.options and config.options.auto_save == true
        end

        if auto_save_enabled then
          process_workspace_autosave(workspace_edit)
        end

        return execution_result
      end
    end,
  })
end

return M
