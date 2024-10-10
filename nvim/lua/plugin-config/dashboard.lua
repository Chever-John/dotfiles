local status, db = pcall(require, 'dashboard')
if not status then
    vim.notify('没有找到 dashboard')
    return
end

local db = require("dashboard")

db.setup({
    theme = 'doom',  -- 使用 doom 主题
    config = {
        header = {
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[]],
            [[                               ▄ ▄                   ]],
            [[ ▄███▄     ▄▄█▀▀██▄ ▀███▄███▀  ███     ▄▄█▀▀██▄ ▀███▄███▀]],
            [[███▀INN██▄███▄▄▄▄███  ███     ███     ██▀    ▀█   ███    ]],
            [['▀▀██▄▄██▀█▀██▀▀▀▀▀▀   ███     ███     ██      █   ███    ]],
            [[ ▀███▀██▄██▄█▄    ▄█   ███     ██▄    ▀█▄▄▄▄▄▀   ███    ]],
            [[▄ ▀█▄██▄█▄ █▄█▄▄███▄█ █▄██▄     █▄█▄    ▄▄█▀▀█▄█ ▄██▄   ]],
            [[                               ▀                     ]],
            [[]],
            [[]],
        },
        week_header = {
            enable = true,  -- 启用星期头部显示
            concat = " - Happy Code Day!",  -- 在时间字符串后添加 " - Happy Code Day!"
            append = {'Embrace coding, embrace life.'}, -- 在时间行后追加更多的行
        },
        disable_move = true,  -- 禁用方向键和 hjkl 移动
        center = {
            {
                icon = '  ',
                desc = 'Projects                            ',
                action = 'Telescope projects',
            },
            {
                icon = '  ',
                desc = 'Find File          ',
                action = 'Telescope find_files',
                shortcut = 'SPC f f'
            },
            {
                icon = '  ',
                desc = 'Search Text        ',
                action = 'Telescope live_grep',
                shortcut = 'SPC f g'
            },
            {
                icon = '  ',
                desc = 'Recent Files       ',
                action = 'Telescope oldfiles',
                shortcut = 'SPC f r'
            },
            {
                icon = '  ',
                desc = 'Edit keybindings                    ',
                action = 'edit ~/.config/nvim/lua/keybindings.lua',
            },
            {
                icon = '  ',
                desc = 'Config             ',
                action = 'edit ~/.config/nvim/init.lua',
                shortcut = 'SPC e v'
            },
            {
                icon = '  ',
                desc = 'Update Plugins     ',
                action = 'PackerSync',
                shortcut = 'SPC p u'
            },
        },
        footer = {
            '',
            'Keep pushing forward!',
        }
    }
})


db.custom_footer = {
    '',
    '',
    'https://github.com/nshen/learn-neovim-lua',
}

db.custom_center = {
    {
        icon = '  ',
        desc = 'Projects                            ',
        action = 'Telescope projects',
    },
    {
        icon = '  ',
        desc = 'Recently files                      ',
        action = 'Telescope oldfiles',
    },
    {
        icon = '  ',
        desc = 'Edit keybindings                    ',
        action = 'edit ~/.config/nvim/lua/keybindings.lua',
    },
    {
        icon = '  ',
        desc = 'Edit Projects                       ',
        action = 'edit ~/.local/share/nvim/project_nvim/project_history',
    },
    -- {
    --   icon = "  ",
    --   desc = "Edit .bashrc                        ",
    --   action = "edit ~/.bashrc",
    -- },
    -- {
    --   icon = "  ",
    --   desc = "Change colorscheme                  ",
    --   action = "ChangeColorScheme",
    -- },
    -- {
    --   icon = "  ",
    --   desc = "Edit init.lua                       ",
    --   action = "edit ~/.config/nvim/init.lua",
    -- },
    -- {
    --   icon = "  ",
    --   desc = "Find file                           ",
    --   action = "Telescope find_files",
    -- },
    -- {
    --   icon = "  ",
    --   desc = "Find text                           ",
    --   action = "Telescopecope live_grep",
    -- },
}

db.custom_header = {
    [[]],
    [[  ██████╗██╗  ██╗███████╗██╗   ██╗███████╗██████╗      ██╗ ██████╗ ██╗  ██╗███╗   ██╗ ]],
    [[ ██╔════╝██║  ██║██╔════╝██║   ██║██╔════╝██╔══██╗     ██║██╔═══██╗██║  ██║████╗  ██║]],
    [[ ██║     ███████║█████╗  ██║   ██║█████╗  ██████╔╝     ██║██║   ██║███████║██╔██╗ ██║]],
    [[ ██║     ██╔══██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗██   ██║██║   ██║██╔══██║██║╚██╗██║]],
    [[ ╚██████╗██║  ██║███████╗ ╚████╔╝ ███████╗██║  ██║╚█████╔╝╚██████╔╝██║  ██║██║ ╚████║]],
    [[  ╚═════╝╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝ ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝]],
}
