# Macrothis.nvim

Macrothis.nvim was created since I had a basic need for storing and loading macros. A side effect is that it works on all registers.

Works with or without telescope.

## Requirements

[Neovim 0.8+](https://github.com/neovim/neovim)

[Telescope](https://github.com/nvim-telescope/telescope.nvim) (optional)


## Using lazy.nvim
```lua
{
    "desdic/macrothis.nvim",
    opts = {},
    keys = {
        { "<Leader>kkd", function() require('macrothis').delete() end, desc = "delete" },
        { "<Leader>kke", function() require('macrothis').edit() end, desc = "edit" },
        { "<Leader>kkl", function() require('macrothis').load() end, desc = "load" },
        { "<Leader>kkn", function() require('macrothis').rename() end, desc = "rename" },
        { "<Leader>kkq", function() require('macrothis').quickfix() end, desc = "run macro on all files in quickfix" },
        { "<Leader>kkr", function() require('macrothis').run() end, desc = "run macro" },
        { "<Leader>kks", function() require('macrothis').save() end, desc = "save" }
    }
},
```

## Telescope

### Enable extension

```lua
require "telescope".load_extension("macrothis")
```

### Configuration

```lua
require("telescope").extensions = {
    macrothis = {}
}
```

### Usage

```
:Telescope macrothis
```

### Default shortcuts

| Shortcut | Description |
| :--- | :--- |
| &lt;CR&gt; | Load selected entry into register |
| &lt;C-d&gt; | Delete selected entry or delete all marked entries |
| &lt;C-e&gt; | Edit content of macro |
| &lt;C-n&gt; | Rename selected entry |
| &lt;C-q&gt; | Run macro on files in quickfix list |
| &lt;C-r&gt; | Run macro |
| &lt;C-s&gt; | Save a macro/register |

Shortcuts, sorters and more can be overridden via telescope options for this plugin.

## Uninstalling

Macrothis keeps a file in the default data directory called macrothis.json
