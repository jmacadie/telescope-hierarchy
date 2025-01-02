local finders = require("telescope.finders")
local actions_state = require("telescope.actions.state")
local transform_mod = require("telescope.actions.mt").transform_mod

local M = {}

M.expand = function(prompt_bufnr)
  local function f()
    local picker = actions_state.get_current_picker(prompt_bufnr)
    ---@type Node
    local node = actions_state.get_selected_entry(prompt_bufnr).value.node

    node:expand(function()
      local new_finder = finders.new_table({
        results = node.root:to_list(),
        entry_maker = picker.finder.entry_maker,
      })

      local selection = picker:get_selection_row()
      local callbacks = { unpack(picker._completion_callbacks) } -- shallow copy
      picker:register_completion_callback(function(self)
        self:set_selection(selection)
        self._completion_callbacks = callbacks
      end)

      picker:refresh(new_finder)
    end)
  end
  return f
end

return transform_mod(M)
