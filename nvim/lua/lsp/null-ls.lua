local status, null_ls = pcall(require, 'null-ls')
if not status then
    vim.notify('没有找到 null-ls')
    return
end

local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local code_actions = null_ls.builtins.code_actions

null_ls.setup({
    debug = false,
    sources = {
        -- Formatting ---------------------
        --  brew install shfmt
        formatting.shfmt,
        -- StyLua
        formatting.stylua,
        -- gofmt
        formatting.gofmt,
        -- dart
        formatting.dart_format,
        -- rust
        formatting.rustfmt,
        -- frontend
        formatting.prettier.with({ -- 只比默认配置少了 markdown
            filetypes = {
                'javascript',
                'javascriptreact',
                'typescript',
                'typescriptreact',
                'vue',
                'css',
                'scss',
                'less',
                'html',
                'json',
                'graphql',
            },
            prefer_local = 'node_modules/.bin',
        }),
        -- formatting.fixjson,
        -- formatting.black.with({ extra_args = { "--fast" } }),

        -- diagnostics
        diagnostics.eslint.with({
            prefer_local = 'node_modules/.bin',
        }),

        -- code code_actions
        code_actions.gitsigns,
        code_actions.eslint.with({
            prefer_local = 'node_modules/.bin',
        }),
    },

    -- #{m}: message
    -- #{s}: source name (defaults to null-ls if not specified)
    -- #{c}: code (if available)
    diagnostics_format = '[#{s}] #{m}',
    -- 保存自动格式化
    on_attach = function(client)
        if client.resolved_capabilities.document_formatting then
            vim.cmd('autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()')
        end
    end,
})
