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

-- 安装列表
-- { key: 语言 value: 配置文件 }
-- 这里的 servers 是一个 字典变量，用来存放所有的 LSP 服务器配置。
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

-- 开始遍历 servers 字典，检查每个 server 是否已经安装，如果没有安装，就调用 install() 方法来安装。
for name, _ in pairs(servers) do
  local server_is_found, server = mason.get_server(name)
  if server_is_found then
    -- 安装服务器
    if not server:is_installed() then
      print("Installing " .. name)
      server:install()
    end
  end
end

mason.on_server_ready(function(server)
  local config = servers[server.name]
  if config == nil then
    return
  end

  if config.on_setup then
    config.on_setup(server)
  else
    server:setup({})
  end
end)

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


require("lsp.ui")
