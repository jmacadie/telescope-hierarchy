local tree = require("telescope-hierarchy.tree")
local telescope = require("telescope-hierarchy.telescope")

local M = {}

M.show = function(opts)
  tree.new(function(root)
    telescope.show_hierarchy(root:to_list(), opts)
  end)
end

return M
