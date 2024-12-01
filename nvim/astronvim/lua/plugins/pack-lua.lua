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

-- 代码结构简单解释：
-- return 返回一个 Lua 表（table），其中包含插件的配置信息。这个表会被 lazy.nvim 用来加载和配置插件。
-- dependencies 也是一个表，列出了当前插件的依赖项。如果当前插件依赖于其他插件，需要将这些依赖插件的名字添加到这个表中。lazy.nvim 会确保在安装当前插件之前先安装所有依赖项。
-- event 指定了触发插件加载的事件。
--    User AstroFile 事件表示在打开文件时触发。
--    InsertEnter 则是在按下回车键时触发，通过指定事件，可以实现插件的延迟加载，从而提高 Neovim 的启动速度。
-- opts 这个表，包含了插件的配置选项。具体的配置内容取决于插件本身的 API。需要查看插件的文档来了解如何配置。

-- 这里有两个 opts，第一个是在 dependencies 中的 opts，第二个是在 根配置项 的 opts。前者作用域在依赖项，后者作用域是当前插件。
