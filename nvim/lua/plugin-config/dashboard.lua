local status, db = pcall(require, 'dashboard')
if not status then
    vim.notify('没有找到 dashboard')
    return
end

-- 获取宜忌信息
local function getYiJi()
  local cmd = "node -e \"console.log(require('${HOME}/.config/nvim/scripts/yiji.js').getTodayYiJi())\""
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()

  local yi = result:match("yi: '(.*)',")
  local ji = result:match("ji: '(.-)'")

  return '宜: ' .. (yi or ""), '忌: ' .. (ji or "")
end

local yi_with_Chinese, ji_with_Chinese = getYiJi()

require("dashboard").setup({
  theme = 'hyper',
  config = {
      week_header = {
          enable = true,
          append = {
              yi_with_Chinese,
              ji_with_Chinese,
          }
      },
      shortcut = {
        { 
          desc = '󰊳 Update',
          group = '@property',
          action = 'PackerSync',
          key = 'u',
        },
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
        {
          desc = '  keybindings',
          group = 'Number',
          action = 'edit ~/.config/nvim/lua/keybindings.lua',
          key = 'k',
        }
      },
    },
})