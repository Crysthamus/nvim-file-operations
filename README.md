# nvim-file-operations
`nvim-file-operations` is a Neovim plugin that adds support for workspace file operations using built-in [LSP](https://neovim.io/doc/user/lsp.html)s. 
This plugin serves as a modern, maintained, and direct drop-in replacement for [`nvim-lsp-file-operations`](https://github.com/antosha417/nvim-lsp-file-operations).
It works by subscribing to events emitted by file managers like [`nvim-tree`](https://github.com/nvim-tree/nvim-tree.lua), [`neo-tree`](https://github.com/nvim-neo-tree/neo-tree.nvim), and [`triptych`](https://github.com/simonmclean/triptych.nvim).

## Features
- **Full Specification Support:** Implements all [`workspace.fileOperations`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_fileOperations) in the current LSP spec:
  - [`workspace/willRenameFiles`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_willRenameFiles)
  - [`workspace/didRenameFiles`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_didRenameFiles)
  - [`workspace/willCreateFiles`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_willCreateFiles)
  - [`workspace/didCreateFiles`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_didCreateFiles)
  - [`workspace/willDeleteFiles`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_willDeleteFiles)
  - [`workspace/didDeleteFiles`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_didDeleteFiles)

It also has faster startup times and better performance than `nvim-lsp-file-operations`
<img width="432" height="40" alt="2026-05-26 11-16-25" src="https://github.com/user-attachments/assets/16f4b8f3-257d-4393-be91-e91b6451042f" />


## Installation

### Using lazy.nvim

```lua
return {
  {
    "Crysthamus/nvim-file-operations",
    dependencies = {
      -- Uncomment whichever supported plugin(s) you use
      -- "nvim-tree/nvim-tree.lua",
      -- "nvim-neo-tree/neo-tree.nvim",
      -- "simonmclean/triptych.nvim"
    },
    config = function()
      require("nvim-file-operations").setup()
    end,
  },
}
```

## Setup
Initialize the plugin with the default configuration:
```lua
require("nvim-file-operations").setup()
```

To override the defaults, pass an options table:
```lua
require("nvim-file-operations").setup({
  -- Select which file operations to enable
  operations = {
    willRenameFiles = true,
    didRenameFiles = true,
    willCreateFiles = true,
    didCreateFiles = true,
    willDeleteFiles = true,
    didDeleteFiles = true,
  },
  -- How long to wait (in milliseconds) for LSP responses before cancelling
  timeout_ms = 10000,
  -- Saves modifies files after renames, moves, etc.
  auto_save = false
})
```

Some LSP servers also expect to be informed about the extended client capabilities.
If you use nvim-lspconfig you can configure the default client capabilities that will be sent to all servers like this:
```lua
local lspconfig = require'lspconfig'

-- Set global defaults for all servers
lspconfig.util.default_config = vim.tbl_extend(
  'force',
  lspconfig.util.default_config,
  {
    capabilities = vim.tbl_deep_extend(
      "force",
      vim.lsp.protocol.make_client_capabilities(),
      -- returns configured operations if setup() was already called
      -- or default operations if not
      require'nvim-file-operations.config'.default_capabilities(),
    )
  }
)
```

## API

### rename(opts)
Renames a file on disk, updates matching Neovim buffers to the new path, and notifies LSP clients.
```lua
require("nvim-file-operations").rename({
  old_name = "path/to/old_file.lua", -- Optional. Defaults to active buffer.
  new_name = "path/to/new_file.lua", -- Required.
})
```

### create(opts)
Creates a new file on disk, ensures parent directories exist, notifies LSP clients, and opens the file.
```lua
require("nvim-file-operations").create({
  fname = "path/to/new_file.lua", -- Required.
})
```

### delete(opts)
```lua
require("nvim-file-operations").delete({
  fname = "path/to/target.lua", -- Optional. Defaults to active buffer.
})
```
