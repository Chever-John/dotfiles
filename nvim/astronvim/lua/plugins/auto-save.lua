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
            callback = function ()
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
            patter = "AutoSaveWritePost",
            callback = function ()
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
  opts = {}
}