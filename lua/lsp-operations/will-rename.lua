local utils = require("lsp-operations.utils")
local config = require("nvim-file-operations.config")
local M = {}

local WILL_RENAME_PATH = { "server_capabilities", "workspace", "fileOperations", "willRename" }

M.callback = function(data)
	local params = {
		files = {
			{
				oldUri = vim.uri_from_fname(data.old_name),
				newUri = vim.uri_from_fname(data.new_name),
			},
		},
	}

	local clients = utils.get_clients()
	for i = 1, #clients do
		local client = clients[i]
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
