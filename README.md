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
        { "<Leader>kks", function() require('macrothis').save() end, desc = "save register" },
        { "<Leader>kkl", function() require('macrothis').load() end, desc = "load register" }
        { "<Leader>kkd", function() require('macrothis').delete() end, desc = "load register" }
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
| &lt;C-s&gt; | Save a macro/register |
| &lt;C-r&gt; | Run macro |
| &lt;C-q&gt; | Run macro on files in quickfix list |

Shortcuts, sorters and more can be overridden via telescope options for this plugin.

## Uninstalling

Macrothis keeps a file in the default data directory called macrothis.json
