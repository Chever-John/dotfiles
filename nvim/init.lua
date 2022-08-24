-- Basic configuration
require('basic')

-- Keybindings
require('keybindings')

-- Packer 插件管理
require('plugins')

-- Theme configuration
require('colorscheme')

-- 插件配置
require("plugin-config.nvim-tree")
require("plugin-config.bufferline")
require("plugin-config.lualine")
require("plugin-config.telescope")
require("plugin-config.dashboard")
require("plugin-config.project")
require("plugin-config.nvim-treesitter")
-- 内置LSP (新增)
require("lsp.setup")
require("lsp.cmp")
require("lsp.ui")
require("plugin-config.indent-blankline")
