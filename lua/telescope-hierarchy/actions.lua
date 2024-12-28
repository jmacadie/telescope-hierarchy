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

return transform_mod(M)
