-------------------------------- Mason --------------------------------
local mason_status, mason = pcall(require, "mason")
if not mason_status then
  vim.notify("没有找到 mason")
  return
end

-- :h mason-default-settings
mason.setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

-------------------------------- Mason LSPConfig --------------------------------
local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
if not mason_lspconfig_status then
  vim.notify("没有找到 mason-lspconfig")
  return
end

-- mason-lspconfig uses the `lspconfig` server names in the APIs it exposes - not `mason.nvim` package names
-- https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
mason_lspconfig.setup({
  -- 确保安装，根据需要填写
  ensure_installed = {
    "bashls",
    "yamlls",
    "gopls",
    "golangci_lint_ls",
  },
  automatic_installation = true -- not the same as ensure_installed
})

-------------------------------- LSPConfig --------------------------------
local lspconfig_status, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status then
  vim.notify("load lspconfig failed")
  return
end


-- 安装列表
-- { key: 语言 value: 配置文件 }
-- key 必须为下列网址列出的名称
-- https://github.com/williamboman/nvim-lsp-installer#available-lsps
local servers = {
    sumneko_lua = require('lsp.config.lua'),
    bashls = require('lsp.config.bash'),

    -- frontend
    -- html = require('lsp.config.html'),
    -- cssls = require('lsp.config.css'),
    -- emmet_ls = require('lsp.config.emmet'),
    -- jsonls = require('lsp.config.json'),
    -- tsserver = require('lsp.config.ts'),

    -- go
    gopls = require('lsp.config.gopls'),

    -- docker
    -- dockerls = require("lsp.config.docker"),

    -- dart
    -- dartls = require('lsp.config.dart'),

    -- rust
    -- rust_analyzer = require('lsp.config.rust'),
}

for name, config in pairs(servers) do
  local server_is_found, server = mason.get_server(name)
  
  if config ~= nil and type(config) == "table" then
    -- 自定义初始化配置文件必须实现on_setup 方法
    config.on_setup(lspconfig[name])
  else
    -- 使用默认参数
    vim.notify("use default config for " .. name)
    lspconfig[name].setup({})
  end
end

require("lsp.ui")
