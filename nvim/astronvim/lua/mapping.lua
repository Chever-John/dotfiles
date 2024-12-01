-- 定义了一个名为 M 的表，用于存储模块的功能。这是一种常见的 lua 模块模式，将所有函数和变量封装在一个表中，避免全局命名空间污染。
local M = {}

-- local system = vim.loop.os_uname().sysname: 获取当前操作系统的名称并存储在 system 变量中。这用于根据不同的操作系统设置不同的按键映射。
local system = vim.loop.os_uname().sysname

-- 定义模块的核心函数 core_mappings，接受一个 mappings 表作为参数。
-- 这个表用于存储按键映射配置。如果未传入 mappings 参数，则使用 require("astrocore").empty_map_table() 创建一个空的映射表。
function M.core_mappings(mappings)
  -- 这段代码确保 mappings 变量不为空。如果调用函数时没有提供 mappings 参数，则会调用 require("astrocore").empty_map_table() 函数创建一个新的空表。这是一种防御性编程的实践，可以避免后续代码出现空指针错误。
  if not mappings then mappings = require("astrocore").empty_map_table() end

  -- 将传入的 mappings 表赋值给局部变量 maps，后续操作都基于 maps 进行，避免直接修改传入的参数。
  local maps = mappings

  -- `if maps then` if `maps` is not nil, then go on.
  if maps then
    -- 禁用 <Leader> 映射
    maps.n["<Leader>n"] = false

    -- 将 Normal 模式下的小写 n 键映射到 utils.better_search 函数，并将参数 “n“ 传递给该函数。
    -- desc 部分是为 which-key 插件添加描述，用于显示按键映射的提示信息。
    -- better_search 函数会处理搜索过程中的错误，并支持数字前缀进行重复搜索。
    maps.n.n = { require("utils").better_search "n", desc = "Next search" }
    maps.n.N = { require("utils").better_search "N", desc = "Previous search" }

    -- 在 Visual Mode 下的按键映射。
    -- 表示在 Visual Mode 模式下，K 是按下大写字母 K 键。
    -- ":move '<-2<CR>gv-gv" 这个命令的意思是 `:move '<-2` 将当前选中的行向上移动两行。
    -- `<CR>` 表示回车键，用于执行命令。
    -- gv 重新选择之前选中的文本，-gv 则取消选中最后一行，保持选中区域不变。
    maps.v["K"] = { ":move '<-2<CR>gv-gv", desc = "Move line up", silent = true }
    maps.v["J"] = { ":move '>+1<CR>gv-gv", desc = "Move line down", silent = true }

    if system == "Darwin" then
      maps.i["<D-s>"] = { "<esc>:w<cr>a", desc = "Save file", silent = true }
      maps.x["<D-s>"] = { "<esc>:w<cr>a", desc = "Save file", silent = true }
      maps.n["<D-s>"] = { "<Cmd>w<cr>", desc = "Save file", silent = true }
    end

    maps.n["n"] = { "nzz" }
    maps.n["N"] = { "Nzz" }

    -- close search highlight
    maps.n["<Leader>nh"] = { ":nohlsearch<CR>", desc = "Close search highlight", silent = true }

    maps.n["H"] = { "^", desc = "Go to start without blank" }
    maps.n["L"] = { "$", desc = "Go to end without blank" }

    maps.v["<"] = { "<gv", desc = "Unindent line" }
    maps.v[">"] = { ">gv", desc = "Indent line" }
    maps.t["<Esc>"] = { [[<C-\><C-n>]], desc = "Exit terminal mode" }

    -- 在visual mode 里粘贴不要复制
    maps.n["x"] = { '"_x', desc = "Cut without copy" }

    maps.n["<Leader>bo"] = maps.n["<Leader>bc"]

    -- lsp restart
    maps.n["<Leader>lm"] = { "<Cmd>LspRestart<CR>", desc = "Lsp restart" }
    maps.n["<Leader>lg"] = { "<Cmd>LspLog<CR>", desc = "Show lsp log" }

    if vim.fn.executable "lazygit" == 1 then
      maps.n["<Leader>tl"] = {
        require("utils").toggle_lazy_git(),
        desc = "ToggleTerm lazygit from Chever",
      }
    end

    if vim.fn.executable "lazydocker" == 1 then
      maps.n["<Leader>td"] = {
        require("utils").toggle_lazy_docker(),
        desc = "ToggleTerm lazydocker",
      }
    end

    if vim.fn.executable "btm" == 1 then
      maps.n["<Leader>tt"] = {
        require("utils").toggle_btm(),
        desc = "ToggleTerm btm",
      }
    end
  end

  return maps
end

function M.lsp_mappings(mappings)
  if not mappings then mappings = require("astrocore").empty_map_table() end
  local maps = mappings
  if maps then
    maps.n["gK"] = false
    maps.n["gk"] = maps.n["<Leader>lh"]
  end
  return maps
end

return M
