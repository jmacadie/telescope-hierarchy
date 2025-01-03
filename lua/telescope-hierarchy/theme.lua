local M = {}

M.apply = function(opts)
  opts = opts or {}

  local theme_opts = {
    theme = "hierarchy",

    results_title = false,
    sorting_strategy = "ascending",
    layout_strategy = "horizontal",
  }

  return vim.tbl_deep_extend("force", theme_opts, opts)
end

return M
