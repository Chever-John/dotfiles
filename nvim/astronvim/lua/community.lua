-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

-- 使用了Lua 类型注解，告诉 Lua 语言服务器（以及其他工具）这个表应该被视为 LazySpec 类型。LazySpec 是 lazy.nvim 定义的类型，
-- 用于描述插件的配置。有助于代码补全和静态分析。
---@type LazySpec
return {
  -- 上面的 return 标志着 Lua 表的开始，该表包含了所有要安装和配置的插件。
  -- 这行代码引入了 astrocommunity 插件集合，它本身不包含具体功能，而是作为其他 astrocommunity 插件的依赖。
  "AstroNvim/astrocommunity",

  -- 这里的配置了 nvim-lsp-file-operations 插件，利用了语言服务器协议（LSP）提供了文件操作相关的功能，例如重命名、移动文件等。
  -- 它增强了 AstroNvim 内置的 LSP 功能。
  { import = "astrocommunity.lsp.nvim-lsp-file-operations" },

  -- 配置了 auto-session-restore 插件，它可以自动保存和恢复 NeoVim 的 Session。这意味着当你关闭 Neovim 后再次打开时
  -- 可以恢复之前的编辑状态，包括打开的文件、光标位置等。
  { import = "astrocommunity.recipes.auto-session-restore" },

  -- 使用了 leetcode 这个插件
  { import = "astrocommunity.game.leetcode-nvim" },

  -- import/override with your plugins folder
  { import = "astrocommunity.test.neotest" },

  -- 这行配置了 nvcheatsheet-nvim 插件，它提供了一个快捷键速查表，可以方便地查看 AstroNvim 中定义的快捷键。
  { import = "astrocommunity.keybinding.nvcheatsheet-nvim" },
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<F1>"] = false,
          ["<F2>"] = {
            function()
              vim.cmd.Neotree "close"
              require("nvcheatsheet").toggle()
            end,
            desc = "Cheatsheet",
          },
        },
      },
    },
  },
}
