local finders = require("telescope.finders")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local transform_mod = require("telescope.actions.mt").transform_mod

local M = {}

M.special_close = function(prompt_bufnr)
  local function f()
    local entry = actions_state.get_selected_entry()
    print(vim.inspect(entry))
    actions.close(prompt_bufnr)
  end
  return f
end

M.add_stuff = function(prompt_bufnr)
  local function f()
    local picker = actions_state.get_current_picker(prompt_bufnr)

    local black = { "black", "#000000" }
    local results = {}
    for exisiting in picker.manager:iter() do
      table.insert(results, exisiting.value)
    end
    table.insert(results, black)

    local new_finder = finders.new_table({
      results = results,
      entry_maker = picker.finder.entry_maker,
    })

    local selection = picker:get_selection_row()
    local callbacks = { unpack(picker._completion_callbacks) } -- shallow copy
    picker:register_completion_callback(function(self)
      self:set_selection(selection)
      self._completion_callbacks = callbacks
    end)

    picker:refresh(new_finder)
  end
  return f
end

return transform_mod(M)
