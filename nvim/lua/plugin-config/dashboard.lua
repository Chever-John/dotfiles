local status, db = pcall(require, 'dashboard')
if not status then
    vim.notify('没有找到 dashboard')
    return
end

-- 获取宜忌信息
local cmd = "node -e \"console.log(require('${HOME}/.config/nvim/scripts/yiji.js').getTodayYiJi())\""
local handle = io.popen(cmd)
local result = handle:read("*a")
handle:close()
local yi = string.match(result, "yi: '(.*)',")

local db = require("dashboard")

db.setup({
    theme = 'hyper',
    config = {
      week_header = {
       enable = true,
       concat = yi, -- 将宜忌信息添加到 week_header 中
      },
      shortcut = {
        { desc = '󰊳 Update', group = '@property', action = 'Lazy update', key = 'u' },
        {
          icon = ' ',
          icon_hl = '@variable',
          desc = 'Files',
          group = 'Label',
          action = 'Telescope find_files',
          key = 'f',
        },
        {
          desc = ' Apps',
          group = 'DiagnosticHint',
          action = 'Telescope app',
          key = 'a',
        },
        {
          desc = ' dotfiles',
          group = 'Number',
          action = 'Telescope dotfiles',
          key = 'd',
        },
      },
    },
})