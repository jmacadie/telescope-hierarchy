--- Holds reference to a function location in the codebase that represents
--- a part of the call hierarchy
---@class Node
---@field text string: The display name of the node
---@field filename string: The filename that contains this node
---@field lnum integer: The (l-based) line number of the reference
---@field col integer: The (1-based) column number of the reference
---@field search_loc lsp.TextDocumentPositionParams: The location in the code to recursively search from
---@field searched boolean: Has this node been searched yet? Searches are expensive so use this flag to only search once
---@field expanded boolean: Is the node expanded in the current representation of the heirarchy tree
---@field root Node: The root of the tree this node is in
---@field children Node[]: A list of the children of this node
---@field lsp LSP: Reference to the module for running calls to the LSP
Node = {}
Node.__index = Node

--- Create a new (unattached) node
---@param uri string: The URI representation of the filename where the node is found
---@param text string: The display name of the node
---@param lnum integer: The (l-based) line number of the reference
---@param col integer: The (1-based) column number of the reference
---@param search_loc lsp.TextDocumentPositionParams: The location in the code to recursively search from
---@param lsp_ref LSP
---@return Node
function Node.new(uri, text, lnum, col, search_loc, lsp_ref)
  local node = {
    filename = vim.uri_to_fname(uri),
    text = text,
    lnum = lnum,
    col = col,
    search_loc = search_loc,
    searched = false,
    expanded = false,
    children = {},
    lsp = lsp_ref,
  }
  -- We need to have a reference to a "root" node to make a valid node
  -- For an unattached node, this will be a self reference
  -- It gets over-written in `add_children`
  node.root = node
  setmetatable(node, Node)
  return node
end

---Process the list of incoming call sites, adding each to the current node's children table
---@param calls lsp.CallHierarchyIncomingCall[]
function Node:add_children(calls)
  for _, call in ipairs(calls) do
    local inner = call.from
    for _, range in ipairs(call.fromRanges) do
      local loc = {
        textDocument = {
          uri = inner.uri,
        },
        position = inner.range.start,
      }
      local child = Node.new(inner.uri, inner.name, range.start.line + 1, range.start.character + 1, loc, self.lsp)
      child.root = self.root -- maintain a common root node
      table.insert(self.children, child)
    end
  end
end

---Search the current node
---It will do nothing if the current node has already been searched
---@param expand boolean Expand the node after searching?
---@param callback fun() Function to be run once all children have been processed
function Node:search(expand, callback)
  if self.searched then
    -- TODO: Maybe should error as this is not an expected state
    return
  end
  local add_cb = function(calls)
    self:add_children(calls)
  end
  local final_cb = function()
    self.expanded = expand
    self.searched = true
    callback()
  end
  self.lsp:incoming_calls(self.search_loc, add_cb, final_cb)
end

---Expand the node, searching for children if not already done
---The callback will not be called if the node is already expanded
---@param callback fun() Function to be run once children have been found (async) & the node expanded
function Node:expand(callback)
  if not self.expanded then
    if self.searched then
      self.expanded = true
      callback()
    else
      self:search(true, callback)
    end
  end
end

---Collapse the node.
---This function is not actually async but it makes sense to write it this way so it can be
---composed with `expand` in a `toggle` method. It also allows the same pattern of not running
---the callback if the node is already collapsed
---@param callback fun()
function Node:collapse(callback)
  if self.expanded then
    self.expanded = false
    callback()
  end
end

---Toggle the expanded state of the node
---Since expanding requires searching for child nodes on the first pass, which is async,
---the entire function is written with the async pattern. The callback contains the following
---code to be run once the node's expanded state has been toggled
---@param callback fun()
function Node:toggle(callback)
  if self.expanded then
    self:collapse(callback)
  else
    self:expand(callback)
  end
end

---@alias NodeLevel {node: Node, level: integer}
---@alias NodeList NodeLevel[]

---Add a node to the list reprsentation of the tree
---There is no return as the list is mutated in place.
---The mutated list is the effective return of this function
---@param list NodeList
---@param node Node
---@param level integer
local function add_node_to_list(list, node, level)
  local entry = {
    node = node,
    level = level,
  }
  table.insert(list, entry)
  if node.expanded and #node.children > 0 then
    for _, child in ipairs(node.children) do
      add_node_to_list(list, child, level + 1)
    end
  end
end

---Convert a node into a list representation of the tree underneath it
---This is needed for Telescope which only works with lists. We retain a memory of the nestedness
---through the level field of the inner table
---@return NodeList
function Node:to_list()
  ---@type NodeList
  local results = {}
  add_node_to_list(results, self, 1)
  return results
end

return Node
