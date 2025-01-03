local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local theme = require("telescope-hierarchy.theme")

local M = {}

---Convert the list of Nodes into a format Telescope can consume
---@param entry NodeLevel
---@return {value: Node, display: string, ordinal: string, filename: string, lnum: integer, col: integer}
local function entry_maker(entry)
  local prefix = ""
  if entry.level > 1 then
    prefix = string.rep("┆ ", entry.level - 2)
    if entry.last then
      prefix = prefix .. "└╴"
    else
      prefix = prefix .. "├╴"
    end
  end
  local display = prefix .. entry.node.text
  return {
    value = entry,
    display = display,
    ordinal = display,
    filename = entry.node.filename,
    lnum = entry.node.lnum,
    col = entry.node.col,
  }
end

-- our picker function: colors
M.show_hierarchy = function(results, opts)
  opts = theme.apply(opts or {})
  opts.initial_mode = "normal"

  pickers
    .new(opts, {
      prompt_title = "Incoming Calls",
      finder = finders.new_table({
        results = results,
        entry_maker = entry_maker,
      }),
      -- No need for a sorter as the tree-view shouldn't be filtered
      -- sorter = conf.generic_sorter(opts),
      previewer = conf.qflist_previewer(opts),
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

return M
