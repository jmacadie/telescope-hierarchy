local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("telescope-hierarchy.nvim requires telescope.nvim - https://github.com/nvim-telescope/telescope.nvim")
end

local defaults = {
  mappings = {
    i = {
      ["<C-e>"] = require("telescope-hierarchy.actions").special_close,
      ["<C-y>"] = require("telescope-hierarchy.actions").add_stuff,
    },
    n = {
      ["e"] = require("telescope-hierarchy.actions").special_close,
      ["y"] = require("telescope-hierarchy.actions").add_stuff,
    },
  },
}

local function extend_config(base, extend)
  local config = vim.tbl_deep_extend("force", base, extend)

  -- remove default keymaps that have been disabled by the user
  for _, mode in ipairs({ "i", "n" }) do
    config.mappings[mode] = vim.tbl_map(function(val)
      return val ~= false and val or nil
    end, config.mappings[mode])
  end

  -- expand theme configs
  if config.theme then
    config = require("telescope.themes")["get_" .. config.theme](config)
  end
  return config
end

local M = {
  exports = {},
}

M.exports.hierarchy = function(config)
  local final_config
  -- skip reevaluation of extend_config if we're updating with an empty table
  if config == nil or next(config) == nil then
    final_config = M.config
  else
    final_config = extend_config(M.config, config)
  end
  require("telescope-hierarchy").show(final_config)
end

M.setup = function(extension_config, _)
  M.config = extend_config(defaults, extension_config)
end

return telescope.register_extension(M)
