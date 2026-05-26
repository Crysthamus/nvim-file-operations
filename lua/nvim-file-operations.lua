local M = {}

---@param opts? Options
function M.setup(opts)
  require("nvim-file-operations.config").setup(opts)
  require("nvim-file-operations.adapters")
end

--- Renames a file on disk, updates matching Neovim buffers, and notifies LSP clients.
---@param opts table { old_name?: string, new_name: string }
M.rename = function(opts)
  opts = opts or {}
  local new_name = opts.new_name

  if not new_name or new_name == "" then
    vim.notify("[nvim-file-operations] new_name is required", vim.log.levels.ERROR)
    return
  end

  local old_name = opts.old_name or vim.api.nvim_buf_get_name(0)
  if not old_name or old_name == "" then
    vim.notify("[nvim-file-operations] No active file to rename", vim.log.levels.ERROR)
    return
  end

  old_name = vim.fn.fnamemodify(old_name, ":p")
  new_name = vim.fn.fnamemodify(new_name, ":p")
  local data = { old_name = old_name, new_name = new_name }

  local ok_will, will_rename = pcall(require, "lsp-operations.will-rename")
  if ok_will then
    will_rename.callback(data)
  end

  local target_dir = vim.fn.fnamemodify(new_name, ":h")
  if vim.fn.isdirectory(target_dir) == 0 then
    vim.fn.mkdir(target_dir, "p")
  end

  local success, err = vim.uv.fs_rename(old_name, new_name)
  if not success then
    vim.notify("[nvim-file-operations] Rename failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  local bufs = vim.api.nvim_list_bufs()
  for i = 1, #bufs do
    local buf = bufs[i]
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == old_name then
      vim.api.nvim_buf_set_name(buf, new_name)
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent! edit!")
      end)
    end
  end

  local ok_did, did_rename = pcall(require, "lsp-operations.did-rename")
  if ok_did then
    did_rename.callback(data)
  end
end

--- Creates a new file on disk, ensures parent directories exist, and notifies LSP clients.
---@param opts table { fname: string }
M.create = function(opts)
  opts = opts or {}
  local fname = opts.fname or opts.name

  if not fname or fname == "" then
    vim.notify("[nvim-file-operations] fname is required", vim.log.levels.ERROR)
    return
  end

  fname = vim.fn.fnamemodify(fname, ":p")
  local data = { fname = fname }

  local ok_will, will_create = pcall(require, "lsp-operations.will-create")
  if ok_will then
    will_create.callback(data)
  end

  local target_dir = vim.fn.fnamemodify(fname, ":h")
  if vim.fn.isdirectory(target_dir) == 0 then
    vim.fn.mkdir(target_dir, "p")
  end

  local fd, err = vim.uv.fs_open(fname, "w", 438)
  if not fd then
    vim.notify("[nvim-file-operations] Create failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  vim.uv.fs_close(fd)

  local ok_did, did_create = pcall(require, "lsp-operations.did-create")
  if ok_did then
    did_create.callback(data)
  end

  vim.cmd("edit " .. vim.fn.fnameescape(fname))
end

--- Deletes a file or directory from disk, wipes matching buffers, and notifies LSP clients.
---@param opts table { fname?: string }
M.delete = function(opts)
  opts = opts or {}
  local fname = opts.fname or opts.name or vim.api.nvim_buf_get_name(0)

  if not fname or fname == "" then
    vim.notify("[nvim-file-operations] No target file to delete", vim.log.levels.ERROR)
    return
  end

  fname = vim.fn.fnamemodify(fname, ":p")
  local data = { fname = fname }

  local ok_will, will_delete = pcall(require, "lsp-operations.will-delete")
  if ok_will then
    will_delete.callback(data)
  end

  local stat = vim.uv.fs_stat(fname)
  if not stat then
    vim.notify("[nvim-file-operations] File does not exist", vim.log.levels.WARN)
    return
  end

  local success, err
  if stat.type == "directory" then
    success, err = vim.uv.fs_rmdir(fname)
  else
    success, err = vim.uv.fs_unlink(fname)
  end

  if not success then
    vim.notify("[nvim-file-operations] Delete failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  local bufs = vim.api.nvim_list_bufs()
  for i = 1, #bufs do
    local buf = bufs[i]
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == fname then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local ok_did, did_delete = pcall(require, "lsp-operations.did-delete")
  if ok_did then
    did_delete.callback(data)
  end
end

return M
