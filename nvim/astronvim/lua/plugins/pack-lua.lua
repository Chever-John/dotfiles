local utils = require "astrocore"

--- check if selene config file exist.
local function selene_configured(path)
  --- use vim.fs.find() function to search selene.toml file
  --- upward = true: search upwards for the existence of the selene.toml file recursively.
  --- # is used to get the length of the returned table.
  return #vim.fs.find("selene.toml", { path = path, upward = true, type = "file" }) > 0
end

---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      ---@diagnostic disable: missing-fields
      config = {
        lua_ls = { settings = { Lua = { hint = { enable = true, arrayIndex = "Disable" } } } },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "lua", "luap" })
      end
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed =
        require("astrocore").list_insert_unique(opts.ensure_installed, { "lua-language-server", "stylua", "selene" })
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        lua = { "selene" },
      },
      linters = {
        --- get the selne configuration.
        selene = { condition = function(ctx) return selene_configured(ctx.filename) end },
      },
    },
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
