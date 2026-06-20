---@class NvimFileOps.Adapters.TreePluginSpec
---@field module string
---@field adapter string

---@class NvimFileOps.Adapters.TreePlugins
---@field NvimTree NvimFileOps.Adapters.TreePluginSpec
---@field ["neo-tree"] NvimFileOps.Adapters.TreePluginSpec
---@field triptych NvimFileOps.Adapters.TreePluginSpec
local tree_plugins = {
  ["NvimTree"] = { module = "nvim-tree", adapter = "nvim-tree" },
  ["neo-tree"] = { module = "neo-tree", adapter = "neo-tree" },
  ["triptych"] = { module = "triptych", adapter = "triptych" },
}

---@param ft "NvimTree"|"neo-tree"|"triptych"
local function setup_adapter(ft)
  local plugin = tree_plugins[ft]
  if plugin and plugin.adapter then
    require("nvim-file-operations.adapters." .. plugin.adapter).setup()
    tree_plugins[ft] = nil
  end
end

for ft, plugin in pairs(tree_plugins) do
  if package.loaded[plugin.module] then
    setup_adapter(ft)
  end
end

---@type string[]
local pending_fts = vim.tbl_keys(tree_plugins)
if #pending_fts > 0 then
  vim.api.nvim_create_autocmd("FileType", {
    pattern = pending_fts,
    callback = function(args)
      setup_adapter(args.match)
    end,
  })
end
