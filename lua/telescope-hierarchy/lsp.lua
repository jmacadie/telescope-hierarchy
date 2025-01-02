---@class LSP
---@field client vim.lsp.Client
---@field bufnr integer
local LSP = {}
LSP.__index = LSP

function LSP.new(client, bufnr)
  local self = {
    client = client,
    bufnr = bufnr,
  }
  setmetatable(self, LSP)
  return self
end

---@private
---@param method string: The method being called
---@param params table
---@param callback function: The function to be called _after_ the LSP request has returned
function LSP:make_request(method, params, callback)
  self.client:request(method, params, function(err, result)
    if err then
      vim.notify(err.message, vim.log.levels.ERROR)
      return
    end
    if result == nil then
      return
    end
    callback(result)
  end, self.bufnr)
end

--- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_prepareCallHierarchy
---@private
---@param position lsp.TextDocumentPositionParams: The location in the code to search from
---@param callback fun(result: lsp.CallHierarchyItem[])
function LSP:prepare_hierarchy(position, callback)
  self:make_request("textDocument/prepareCallHierarchy", position, callback)
end

--- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#callHierarchy_incomingCalls
---@param position lsp.TextDocumentPositionParams: The location in the code to search from
---@param each_cb fun(calls: lsp.CallHierarchyIncomingCall[]) Callback to be run on every return from callHierarchy/incomingcalls
---@param final_cb fun() Callback to be run once all incomingcalls requests have resolved
function LSP:incoming_calls(position, each_cb, final_cb)
  self:prepare_hierarchy(position, function(result)
    if result == nil then
      return
    end
    local results_counter = #result
    for _, item in ipairs(result) do
      self:make_request("callHierarchy/incomingCalls", { item = item }, function(calls)
        each_cb(calls)
        -- Trigger the final callback once all requests are done
        results_counter = results_counter - 1
        if results_counter == 0 then
          final_cb()
        end
      end)
    end
  end)
end

return LSP
