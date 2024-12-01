--- 这段代码旨在定制 AstroNvim 中的 Telescope 插件的行为，涵盖了键映射、默认设置以及特定选择器的配置。
---
--- 第一行代码，导入了 astrocore 模块的 is_available 函数。该函数用于检查某个插件是否已安装并可用，避免在插件缺失时引发错误。
local is_available = require("astrocore").is_available
---@type LazySpec
return {
  "nvim-telescope/telescope.nvim",
  --- 开始配置 AstroNvim 的核心插件（astrocore）。这里主要用于修改 astrocore 的 mappings 表，从而添加或更改 telescope 的 键映射。
  specs = {
    {
      "AstroNvim/astrocore",
      ---@param opts AstroCoreOpts
      opts = function(_, opts)
        --- 使用一个函数来修改其选项。
        ---
        --- 如果 mappings 不存在，那么就创建一个新的空表。为了防止在 mappings 表不存在时出现错误。
        if not opts.mappings then opts.mappings = require("astrocore").empty_map_table() end
        local maps = opts.mappings
        if maps then
          -- telescope plugin mappings
          if is_available "telescope.nvim" then
            --- enter <Leader>f in visual mode and show a search menu, desc is "Find".
            maps.v["<Leader>f"] = { desc = "󰍉 Find" }

            --- enter <Leader>fT in normal mode and execute `TodoTelescope` to find the TODO comments.
            maps.n["<Leader>fT"] = { "<cmd>TodoTelescope<cr>", desc = "Find TODOs" }


            --- map the '<Leader>fO' to the '<Leader>fo'.
            maps.n["<Leader>fO"] = maps.n["<Leader>fo"]

            --- In normal mode, open Telescope file browser, and set current path to the path.
            --- select_buffer=true allow to select the opened buffers.
            maps.n["<Leader>fo"] = {
              "<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>",
              desc = "Open File browser in cwd path",
            }

            --- 
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

    --- use the extend_tbl to merge the defaults config and current config.
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

