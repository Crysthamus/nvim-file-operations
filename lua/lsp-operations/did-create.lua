local utils = require("lsp-operations.utils")
local M = {}

local DID_CREATE_PATH = { "server_capabilities", "workspace", "fileOperations", "didCreate" }

M.callback = function(data)
	local params = {
		files = { { uri = vim.uri_from_fname(data.fname) } },
	}

	local clients = utils.get_clients()
	for i = 1, #clients do
		local client = clients[i]
		local did_create = utils.get_nested_path(client, DID_CREATE_PATH)

		if did_create and utils.matches_filters(did_create.filters, data.fname) then
			client:notify("workspace/didCreateFiles", params)
		end
	end
end

return M
