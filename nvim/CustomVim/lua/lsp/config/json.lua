local opts = {
    settings = {
        json = {
            schemas = require('schemastore').json.schemas(),
        },
    },
    capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities()),
    flags = {
        debounce_text_changes = 150,
    },
    on_attach = function(client, _)
        client.server_capabilities.document_formatting = false
        client.server_capabilities.document_range_formatting = false
    end,
}

return {
    on_setup = function(server)
        server:setup(opts)
    end,
}
