local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local themes = require("telescope.themes")
local conf = require("telescope.config").values

-- our picker function: colors
local colors = function(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "colors",
      finder = finders.new_table({
        results = {
          { "red", "#ff0000" },
          { "green", "#00ff00" },
          { "blue", "#0000ff" },
        },
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry[1],
            ordinal = entry[1],
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
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
  colors(themes.get_dropdown(opts))
end

return M
