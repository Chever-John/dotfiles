# 学习 AstroNvim

记录一下自己通过 AstroNvim 学习。

## 使用 vim.lsp.protocol.Methods

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

## 介绍两种 opts 字段的赋值方法

下面这种

```lua
---@type LazySpec
return {
"AstroNvim/astrocore",
 version = false,
 branch = "v2",
---@type AstroCoreOpts
---@diagnostic disable-next-line: assign-type-mismatch
opts = function(_, opts)
end,
}
```

和下面这种

```lua
---@type LazySpec
return {
"AstroNvim/astrocore",
 version = false,
 branch = "v2",
---@type AstroCoreOpts
---@diagnostic disable-next-line: assign-type-mismatch
opts = {
},
}
```

这两段代码都是 AstroNvim 中用于配置 `astrocore` 插件的 Lua 代码片段。他们的主要区别在于 `opts` 字段的赋值方式：

### **第一段代码**

```lua
opts = function(_, opts)
end,
```

这里 `opts` 被赋值为一个匿名函数。这个函数接受两个参数：`_` 和 `opts`。`_` 通常用于表示一个未使用的参数，而 `opts` 则是 `astrocore` 插件的默认选项表。这个函数的返回值将作为最终的 `astrocore` 配置选项。

这种写法的主要目的是 **修改或扩展** `astrocore` 的默认配置。在函数内部，你可以访问和修改 `opts` 表中的各个选项，然后返回修改后的 `opts` 表。由于函数体为空，这段代码实际上并没有对默认配置做任何修改，等同于使用默认配置。

### **第二段代码**

```lua
opts = {
},
```

这里 `opts` 被赋值为一个空表 `{}`。这意味着你**完全覆盖**了 `astrocore` 的默认配置，最终使用的配置就是一个空表。这会导致 `astrocore` 的许多默认功能失效。

### **总结**

- 第一段代码使用函数，可以修改或扩展默认配置，但当前示例等同于使用默认配置。
- 第二段代码使用空表，完全覆盖默认配置，导致默认功能失效。

### **最佳实践**

在 AstroNvim 中配置插件时，通常建议使用函数来修改默认配置，而不是直接覆盖。这样可以保留插件的默认功能，并根据需要进行调整。例如，如果你只想修改 `astrocore` 的某个特定选项，可以这样写：

```lua
opts = function(_, opts)
  opts.disabled_plugins = { "trouble.nvim" } -- 禁用 trouble.nvim 插件
  return opts
end,
```

这种方式既保留了 `astrocore` 的其他默认配置，又实现了你想要的功能。

### **关于 `version = false` 和 `branch = "v2"`**

- `version = false`: 表示不锁定插件版本，始终使用最新的版本。
- `branch = "v2"`: 指定使用 `v2` 分支的代码。这通常用于测试或使用开发版本的插件。

### **关于 `---@type AstroCoreOpts` 和 `---@diagnostic disable-next-line: assign-type-mismatch`**

- `---@type AstroCoreOpts`: 这是 Lua 的类型注解，用于告诉 Lua 语言服务器 (LSP) `opts` 变量的类型是 `AstroCoreOpts`。这有助于代码补全和类型检查。
- `---@diagnostic disable-next-line: assign-type-mismatch`: 这是用于禁用下一行代码的类型不匹配警告的注释。有时由于类型推断的限制，LSP 可能会误报类型错误，这时可以使用这个注释来抑制警告。
