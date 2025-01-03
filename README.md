# Telescope Hierarchy

A [Telescope](https://github.com/nvim-telescope/telescope.nvim) extension for navigating the call hierarchy. It works through the attached LSP, so if the LSP doesn't offer call hierarchy, [Lua-ls](https://github.com/LuaLS/lua-language-server) I'm 👀 at you, this extension won't do anything.

Currently it only works on incoming calls. These are the other places in the codebase that the current function is called, and then the other places that those functions are called, and so on... The full call stack is a tree of affected functions that needs to be explored recursively.

# Usage

`:Telescope hierarchy` opens a Telescope window. It finds all incoming calls (i.e. other functions) of the function under the current cursor. Recursive searches are only done on request when the function node is first attempted to be expanded.

The finder window is opened in normal model, since filtering the results tree doesn't make much sense.

The following keymaps are set:

| Key | Action |
| --- | --- |
| `e`, `l`, `→` | Expand the current node: this will recursively find all incoming calls |
| `c`, `h`, `←` | Collapse the current node: the child calls are still found, just hidden in the finder window |
| `t` | Toggle the expanded state of the current node |
| `CR` | Navigate to the function call shown |
| `q`, `ESC` | Quit the Telescope finder |

# Install

Use Lazy:
```lua ...\lua\plugins\telescope-hierarchy.lua
return {
	"jmacadie/telescope-hierarchy.nvim",
	dependencies = {
		{
			"nvim-telescope/telescope.nvim",
			dependencies = { "nvim-lua/plenary.nvim" },
		},
	},
	keys = {
		{ -- lazy style key map
			"<leader>xx",
			"<cmd>Telescope hierarchy<cr>",
			desc = "Search Hierarchy",
		},
	},
	opts = {
		-- don't use `defaults = { }` here, do this in the main telescope spec
		extensions = {
			hierarchy = {
				-- telescope-hierarchy.nvim config, see below
			},
			-- no other extensions here, they can have their own spec too
		},
	},
	config = function(_, opts)
		-- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
		-- configs for us. We won't use data, as everything is in it's own namespace (telescope
		-- defaults, as well as each extension).
		require("telescope").setup(opts)
		require("telescope").load_extension("hierarchy")
	end,
}
```

# Config

The usual [Telescope config options](https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#customization) can be used with this extension

# See Also

This extension is very new, there may well be better options for you

- [telescope-undo.nvim](https://github.com/debugloop/telescope-undo.nvim/tree/main) showed me that a treeview was possible in the finder window and * ahem * inspired certain parts of this extension's code
- [hierarchy-tree-go.nvim](https://github.com/crusj/hierarchy-tree-go.nvim) not integrated with Telescope, tied to Go & looks to be no longer maintained but it does exactly what we're trying to do here and the LSP calls all seem to be of the same structure
- [nvimdev](https://nvimdev.github.io/lspsaga/callhierarchy/) not integrated with Telescope & part of a larger suite of LSP tools. For now certainly, this is a better, more mature solution to the problem
- [Telescope builtin](https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/builtin/__lsp.lua#L113) Telescope has it's own call hierarchy builtin. It just makes the first level call, and so to get recursive search you would need to navigate to the next code call and then call hierarchy again
- [Neovim](https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/buf.lua#L907) The core Neovim runtime lua offers a way to run the call hierarchy. Like the Telescope builtin, it is only one level deep. It dumps the results in the quickfix list. Depending on your situation, you may just want to use the core stuff. It's good and will always be maintained. See also [this issue](https://github.com/neovim/neovim/issues/26817)

# Roadmap

- Make the initial find smarter. It will _only_ work if the cursor is on the function name. I think it would be preferable to be triggerable from anywhere on the function declaration line (or lines)
- Make the Finder window a bit prettier
  - Include a little fx icon for the function names
  - Show when we have an unknown node
  - Show the child count of collapsed nodes
  - Use different colours for the different parts
  - Show file names and/or line positions?
- Include Outgoing calls
  - Once we have outgoing calls, should be able to select a node (function call) and switch from incoming to outgoing calls, and vice versa
- Include a history, to go back to a previous call history state. This will be useful once we can toggle between incoming and outgoing calls, as this will need to re-render the root node, losing the previous root in the process
- Use the same infrastructure to show Class hierarchies as well. It's basically the same thing
