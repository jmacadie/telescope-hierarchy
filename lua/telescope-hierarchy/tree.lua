local log = require("telescope-hierarchy.log")

local M = {}

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

--- Create a new (unattached) node
---@param uri string: The URI representation of the filename where the node is found
---@param text string: The display name of the node
---@param lnum integer: The (l-based) line number of the reference
---@param col integer: The (1-based) column number of the reference
---@param search_loc lsp.TextDocumentPositionParams: The location in the code to recursively search from
---@return Node
local create_node = function(uri, text, lnum, col, search_loc)
  local node = {
    filename = vim.uri_to_fname(uri),
    text = text,
    lnum = lnum,
    col = col,
    search_loc = search_loc,
    searched = false,
    expanded = false,
    children = {},
  }
  node.root = node
  return node
end

---@param client vim.lsp.Client: The LSP
---@param bufnr integer: The buffer number
---@param method string: The method being called
---@param params table
---@param callback function: The function to be called _after_ the LSP request has returned
local make_request = function(client, bufnr, method, params, callback)
  client:request(method, params, function(err, result)
    if err then
      vim.notify(err.message, vim.log.levels.ERROR)
      return
    end
    if result == nil then
      return
    end
    callback(result)
  end, bufnr)
end

--- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_prepareCallHierarchy
---@param position lsp.TextDocumentPositionParams: The location in the code to search from
---@param callback function
---@param bufnr integer: The buffer number
local prepare_hierarchy = function(client, bufnr, position, callback)
  local prepare = "textDocument/prepareCallHierarchy"
  make_request(client, bufnr, prepare, position, callback)
end

--- Creates the root node
---@param client vim.lsp.Client
---@return Node
local create_root = function(client)
  -- TODO: check we are on a function declaration
  local current_position = vim.lsp.util.make_position_params(0, client.offset_encoding)
  local uri = current_position.textDocument.uri
  local text = vim.fn.expand("<cword>")
  local lnum = current_position.position.line + 1
  local col = current_position.position.character + 1
  return create_node(uri, text, lnum, col, current_position)
end

---@param clients vim.lsp.Client[]
---@param callback fun(client: vim.lsp.Client) The next async function to be called with the chosen LSP client
---@return nil This function does not return anything, the continued execution comes from calling the callback function
local function pick_client(clients, callback)
  if #clients == 0 then
    vim.notify("No LSPs attached that will generate a call hierarchy", vim.log.levels.WARN)
    return
  end
  if #clients == 1 then
    callback(clients[1])
    return
  end
  vim.ui.select(clients, {
    prompt = "More than one possible LSP. Please choose which to use",
    format_item = function(lsp)
      return lsp.name
    end,
  }, callback)
end

--- Use the LSP to find all the children of a supplied node
--- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#callHierarchy_incomingCalls
---@param client vim.lsp.Client
---@param bufnr integer
---@param node Node
---@param callback fun()
local add_children = function(client, bufnr, node, callback)
  prepare_hierarchy(client, bufnr, node.search_loc, function(results)
    if results == nil then
      return
    end
    for idx, item in ipairs(results) do
      make_request(client, bufnr, "callHierarchy/incomingCalls", { item = item }, function(calls)
        for _, call in ipairs(calls) do
          local inner = call["from"]
          for _, range in ipairs(call.fromRanges) do
            local loc = {
              textDocument = {
                uri = inner.uri,
              },
              position = inner.range.start,
            }
            local child = create_node(inner.uri, inner.name, range.start.line + 1, range.start.character + 1, loc)
            child.root = node.root
            log.trace(vim.inspect(child))
            table.insert(node.children, child)
          end
        end
        -- Trigger the callback once all requests are done
        if idx == #results then
          log.trace(vim.inspect(node))
          callback()
        end
      end)
    end
  end)
end

---@class Tree
---@field root Node
---@field client vim.lsp.Client
---@field bufnr integer

--- Create a new tree from the current position. Since these LSP calls are async, we can
--- only create this new tree async as well so will need to hand it to a callback handler
--- when we're finally done
---@param callback fun(tree: Tree): nil The function that will be passed the new tree to then use
M.new = function(callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ method = "textDocument/prepareCallHierarchy", bufnr = bufnr })
  if #clients == 0 then
    vim.notify("No LSPs attached that will generate a call hierarchy", vim.log.levels.WARN)
    return
  end
  pick_client(clients, function(client)
    local root = create_root(client)
    add_children(client, bufnr, root, function()
      root.expanded = true
      root.searched = true
      local tree = { root = root, client = client, bufnr = bufnr }
      callback(tree)
    end)
  end)
end

local add_node_to_list

---@alias NodeList {node: Node, level: integer}[]

---Add a node to the list reprsentation of the tree
---There is no return as the list is mutated in place. The mutated list is the effective return
---of this function
---@param list NodeList
---@param node Node
---@param level integer
add_node_to_list = function(list, node, level)
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

---Convert a tree into a list representation of the tree
---This is needed for Telescope which only works with lists. We retain a memory of the nestedness
---through the level field of the inner table
---@param tree Tree
---@return NodeList
M.to_list = function(tree)
  ---@type NodeList
  local results = {}
  add_node_to_list(results, tree.root, 1)
  return results
end

return M
