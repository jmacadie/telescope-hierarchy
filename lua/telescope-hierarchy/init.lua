local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local themes = require("telescope.themes")
-- local conf = require("telescope.config").values
local tree = require("telescope-hierarchy.tree")

---Convert the list of Nodes into a format Telescope can consume
---@param entry NodeList
---@return {value: Node, display: string, ordinal: string}
local entry_maker = function(entry)
  local display = entry.level .. entry.node.text
  return {
    value = entry,
    display = display,
    ordinal = display,
  }
end

-- our picker function: colors
local show_hierarchy = function(results, opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "colors",
      finder = finders.new_table({
        results = results,
        entry_maker = entry_maker,
      }),
      -- sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        for _, mode in pairs({ "i", "n" }) do
          for key, get_action in pairs(opts.mappings[mode] or {}) do
            map(mode, key, get_action(prompt_bufnr))
          end
        end
        return true -- include defaults as well
      end,
    })
    :find()
end

local M = {}

M.show = function(opts)
  tree.new(function(t)
    local list = tree.to_list(t)
    local themed_opts = themes.get_dropdown(opts)
    show_hierarchy(list, themes.get_dropdown(themed_opts))
  end)
end

return M
