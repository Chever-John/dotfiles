# 学习 AstroNvim

我发现了一个不熟悉的配置，如下：

```lua
-- astrolsp.lua
local methods = vim.lsp.protocol.Methods

local rename_handler = vim.lsp.handlers[methods.textDocument_rename]
local auto_save_after_rename_handler = function(err, result, ctx, config)
  rename_handler(err, result, ctx, config)

  if not result or not result.documentChanges then return end

  for _, documentChange in pairs(result.documentChanges) do
    local textDocument = documentChange.textDocument
    if textDocument and textDocument.uri then
      local bufnr = vim.uri_to_bufnr(textDocument.uri)
      if vim.fn.bufloaded(bufnr) == 1 then
        vim.schedule(function()
          vim.api.nvim_buf_call(bufnr, function() vim.cmd "write" end)
        end)
      end
    end
  end
end


---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    -- ............
    lsp_handlers = {
      [methods.textDocument_rename] = auto_save_after_rename_handler,
    },
  },
}
```

上面配置了根据文件存储。旨在修改 AstroNvim 中 LSP 重命名操作后自动保存文件。

```lua
local methods = vim.lsp.protocol.Methods
```

上面的代码获取了所有可用的 LSP 方法，并将其存储在 `methods` 变量中。这使得后续代码可以通过 `methods.textDocument_rename` 来获取重命名方法，更清晰，提高代码可读性。

```lua
local rename_handler = vim.lsp.handlers[methods.textDocument_rename]
```

这行代码获取了重命名方法的处理器，并将其存储在 `rename_handler` 变量中。这是为了在自定义的自动保存逻辑中仍然保留原有的重命名功能。

```lua
local auto_save_after_rename_handler = function(err, result, ctx, config)
```

这行代码定义了一个自动保存的处理器函数，该函数接收了 4 个参数，分别是 `err` (错误信息)、`result` (结果)、`ctx` (上下文和配置)。这是为了在重命名操作完成后，自动保存文件。

```lua
rename_handler(err, result, ctx, config)
```
