local Tree = require('nvim-treesitter')
local Tele = require('telescope')
local ts = vim.treesitter
local parsers = require('nvim-treesitter.parsers')

local M = {}
local H = {}

M.get_class_name = function()
  local class_name = [[
    (class_declaration
      name: (identifier) @class_name
    )
  ]]
  local class_name_query = H.build_query(class_name)
  local root = parsers.get_parser():parse()[1]:root()

  local result = H.get_matched_node_names(class_name_query, 1, root)
  if not next(result) then
    return nil
  end
  return result[1]
end

return M
