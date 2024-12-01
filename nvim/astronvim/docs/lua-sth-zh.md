# 讲解一下基本的 lua 知识

```lua
---@type LazySpec
return {
  "chaozwn/auto-save.nvim",
  dependencies = {
    "AstroNvim/astrocore",
    opts = {
      autocmds = {
        autoformat_toggle = {
          -- Disable autoformat before saving
          {
            event = "User",
            desc = "Disable autoformat before saving",
            pattern = "AutoSaveWritePre",
            callback = function()
              -- Save global autoformat status
              vim.g.OLD_AUTOFORMAT = vim.g.autoformat
              vim.g.autoformat = false
              vim.g.OLD_AUTOFORMAT_BUFFERS = {}
              -- Disable all manually enabled buffers
              for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.b[bufnr].autoformat then
                  table.insert(vim.g.OLD_AUTOFORMAT_BUFFERS, bufnr)
                  vim.b[bufnr].autoformat = false
                end
              end
            end,
          },
          -- Re-enable autoformat after saving
          {
            event = "User",
            desc = "Re-enable autoformat after saving",
            pattern = "AutoSaveWritePost",
            callback = function()
              -- Restore global autoformat status
              vim.g.autoformat = vim.g.OLD_AUTOFORMAT
              -- Re-enable all manually enabled buffers
              for _, bufnr in ipairs(vim.g.OLD_AUTOFORMAT_BUFFERS or {}) do
                vim.b[bufnr].autoformat = true
              end
            end,
          },
        },
      },
    },
  },
  event = { "User AstroFile", "InsertEnter" },
  opts = {
    debounce_delay = 3000,
    print_enabled = false,
    trigger_events = { "TextChanged" },
    condition = function(buf)
      local fn = vim.fn
      local utils = require "auto-save.utils.data"

      if fn.getbufvar(buf, "&modifiable") == 1 and utils.not_in(fn.getbufvar(buf, "&filetype"), {}) then
        -- check weather not in normal mode
        if fn.mode() ~= "n" then
          return false
        else
          return true
        end
      end
      return false -- can't save
    end,
  },
}
```

代码结构简单解释：
return 返回一个 Lua 表（table），其中包含插件的配置信息。这个表会被 lazy.nvim 用来加载和配置插件。
dependencies 也是一个表，列出了当前插件的依赖项。如果当前插件依赖于其他插件，需要将这些依赖插件的名字添加到这个表中。lazy.nvim 会确保在安装当前插件之前先安装所有依赖项。
event 指定了触发插件加载的事件。
User AstroFile 事件表示在打开文件时触发。
InsertEnter 则是在按下回车键时触发，通过指定事件，可以实现插件的延迟加载，从而提高 Neovim 的启动速度。
opts 这个表，包含了插件的配置选项。具体的配置内容取决于插件本身的 API。需要查看插件的文档来了解如何配置。

这里有两个 opts，第一个是在 dependencies 中的 opts，第二个是在 根配置项 的 opts。前者作用域在依赖项，后者作用域是当前插件。

## autocmds

这个配置来源于 `AstroNvim/astrocore` 插件本身。并非 Neovim 或 Lua 的标准约定，而是 `astrocore` 插件开发者自定义的配置方式。

要理解这个配置的来源，我们需要了解以下几点：

1. **`AstroNvim/astrocore` 的作用:** `astrocore` 是 AstroNvim 发行版的基础插件，它提供了一些核心功能和配置，用于管理 AstroNvim 的其他组件。
2. **`autocmds` 在 `astrocore` 中的用途:** `astrocore` 使用 `autocmds` 来管理各种自动化任务，例如：
    1. 文件类型检测；
    2. LSP 配置；
    3. 格式化等等。

​	通过 `autocmds`，`astrocore` 可以在特定事件发生时执行相应的操作。

1. **`opts.autocmds` 的作用:** `opts.autocmds` 允许用户自定义或覆盖 `astrocore` 内置的 `autocmds`。你提供的代码片段正是利用了这个机制，在自动保存前后禁用和重新启用自动格式化功能。
2. **约定俗成的配置方式:** 虽然 `opts.autocmds` 是 `astrocore` 自定义的配置方式，但它遵循了 Neovim 的 `autocmd` 机制。因此，在配置 `autocmds` 时，你需要使用 Neovim 的 `autocmd` 事件和命令。

**如何找到 `autocmds` 配置的定义:**

要找到 `opts.autocmds` 支持的具体配置项，你需要查阅 `AstroNvim/astrocore` 插件的文档或源码。通常，插件开发者会在文档中说明如何配置 `opts`，或者在源码中定义 `opts` 的结构。

**总结:**

`autocmds` 配置并非标准的 Lua 或 Neovim 约定，而是 `AstroNvim/astrocore` 插件自定义的配置方式，用于管理自动化任务。要了解具体的配置选项，你需要查阅 `astrocore` 的文档或源码。
