local is_available = require("astrocore").is_available
---@type LazySpec
return {
  "nvim-telescope/telescope.nvim",
  specs = {
    {
      "AstroNvim/astrocore",
      ---@param opts AstroCoreOpts
      opts = function(_, opts)
        if not opts.mappings then opts.mappings = require("astrocore").empty_map_table() end
        local maps = opts.mappings
        if maps then
          -- telescope plugin mappings
          if is_available "telescope.nvim" then
            maps.v["<Leader>f"] = { desc = "󰍉 Find" }
            maps.n["<Leader>fT"] = { "<cmd>TodoTelescope<cr>", desc = "Find TODOs" }

            maps.n["<Leader>fO"] = maps.n["<Leader>fo"]

            maps.n["<Leader>fo"] = {
              "<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>",
              desc = "Open File browser in cwd path",
            }
            maps.n["<Leader>fe"] = { "<Cmd>Telescope file_browser<CR>", desc = "Open File browser in current path" }
          end
        end
        opts.mappings = maps
      end,
    },
  },
  dependencies = {
    "nvim-lua/popup.nvim",
    "nvim-lua/plenary.nvim",
    "AstroNvim/astroui",
  },
  opts = function(_, opts)
    local actions = require "telescope.actions"

    return require("astrocore").extend_tbl(opts, {
      defaults = {
        prompt_prefix = "   ",
        selection_caret = " ",
        entry_prefix = " ",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
          width = 0.87,
          height = 0.80,
        },
      },
      pickers = {
        find_files = {
          -- dot file
          hidden = true,
        },
        buffers = {
          path_display = { "smart" },
          mappings = {
            i = { ["<C-d>"] = actions.delete_buffer + actions.move_to_top },
            n = { ["d"] = actions.delete_buffer + actions.move_to_top },
          },
        },
      },
      extensions = {},
    })
  end,
  config = function(...) require "astronvim.plugins.configs.telescope"(...) end,
}

