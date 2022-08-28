vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local map = vim.api.nvim_set_keymap
-- 复用 opt 参数
local opt = { noremap = true, silent = true }

-- 窗口管理快捷键映射
-- 1. 取消 s 默认功能
map('n', 's', '', opt)

-- 2. 分屏快捷键
map('n', 'sv', ':vsp<CR>', opt)
map('n', 'sh', ':sp<CR>', opt)

-- 3. 关闭当前
map('n', 'sc', '<C-w>c', opt)

-- 4. 关闭其他
map('n', 'so', '<C-w>o', opt)

-- 5. macOS 中是 Option + hjkl 窗口之间跳转
map('n', '<A-h>', '<C-w>h', opt)
map('n', '<A-j>', '<C-w>j', opt)
map('n', '<A-k>', '<C-w>k', opt)
map('n', '<A-l>', '<C-w>l', opt)

-- 6. 左右比例控制
map('n', '<C-Left>', ':vertical resize -2<CR>', opt)
map('n', '<C-Right>', ':vertical resize +2<CR>', opt)
map('n', 's,', ':vertical resize -20<CR>', opt)
map('n', 's.', ':vertical resize +20<CR>', opt)

-- 7. 上下比例控制
map('n', 'sj', ':resize +10<CR>', opt)
map('n', 'sk', ':resize -10<CR>', opt)
map('n', '<C-Down>', ':resize +2<CR>', opt)
map('n', '<C-Up>', ':resize -2<CR>', opt)

-- 8. 等比例
map('n', 's=', '<C-w>=', opt)

-- 9. Terminal 相关
map('n', '<leader>t', ':sp | terminal<CR>', opt)
map('n', '<leader>vt', ':vsp | terminal<CR>', opt)
map('t', '<Esc>', '<C-\\><C-n>', opt)
map('t', '<A-h>', [[ <C-\><C-N><C-w>h ]], opt)
map('t', '<A-j>', [[ <C-\><C-N><C-w>j ]], opt)
map('t', '<A-k>', [[ <C-\><C-N><C-w>k ]], opt)
map('t', '<A-l>', [[ <C-\><C-N><C-w>l ]], opt)

-- 插件快捷键
local pluginKeys = {}

-- Telescope
-- 查找文件
map('n', '<C-p>', ':Telescope find_files<CR>', opt)
-- 全局搜索
map('n', '<C-f>', ':Telescope live_grep<CR>', opt)

-- bufferline
-- 左右Tab切换，注意 macOS 中好像并不能使用 C-h，因为 macOS 好像没有默认的 Ctrl 键
map('n', '<C-h>', ':BufferLineCyclePrev<CR>', opt)
map('n', '<C-l>', ':BufferLineCycleNext<CR>', opt)
-- 关闭

--"moll/vim-bbye"
map('n', '<C-w>', ':Bdelete!<CR>', opt)
map('n', '<leader>bl', ':BufferLineCloseRight<CR>', opt)
map('n', '<leader>bh', ':BufferLineCloseLeft<CR>', opt)
map('n', '<leader>bc', ':BufferLinePickClose<CR>', opt)

-- nvim-tree
-- alt + m 键打开关闭tree
map('n', '<A-m>', ':NvimTreeToggle<CR>', opt)

-- lsp 回调函数快捷键设置
pluginKeys.mapLSP = function(mapbuf)
    -- rename
    --[[
  Lspsaga 替换 rn
  mapbuf("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opt)
  --]]
    mapbuf('n', '<leader>rn', '<cmd>Lspsaga rename<CR>', opt)
    -- code action
    --[[
  Lspsaga 替换 ca
  mapbuf("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opt)
  --]]
    mapbuf('n', '<leader>ca', '<cmd>Lspsaga code_action<CR>', opt)
    -- go xx
    --[[
    mapbuf('n', 'gd', '<cmd>Lspsaga preview_definition<CR>', opt)
  --]]
    mapbuf('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opt)
    --[[
  Lspsaga 替换 gh
  mapbuf("n", "gh", "<cmd>lua vim.lsp.buf.hover()<CR>", opt)
  --]]
    mapbuf('n', 'gh', '<cmd>Lspsaga hover_doc<cr>', opt)
    --[[
  Lspsaga 替换 gr
  mapbuf("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opt)
  --]]
    mapbuf('n', 'gr', '<cmd>Lspsaga lsp_finder<CR>', opt)
    --[[
  Lspsaga 替换 gp, gj, gk
  mapbuf("n", "gp", "<cmd>lua vim.diagnostic.open_float()<CR>", opt)
  mapbuf("n", "gj", "<cmd>lua vim.diagnostic.goto_next()<CR>", opt)
  mapbuf("n", "gk", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opt)
  --]]
    -- diagnostic
    mapbuf('n', 'gp', '<cmd>Lspsaga show_line_diagnostics<CR>', opt)
    mapbuf('n', 'gj', '<cmd>Lspsaga diagnostic_jump_next<cr>', opt)
    mapbuf('n', 'gk', '<cmd>Lspsaga diagnostic_jump_prev<cr>', opt)
    mapbuf('n', '<leader>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opt)
    -- 未用
    -- mapbuf("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opt)
    -- mapbuf("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opt)
    -- mapbuf('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opt)
    -- mapbuf("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opt)
    -- mapbuf('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opt)
    -- mapbuf('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opt)
    -- mapbuf('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opt)
    -- mapbuf('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opt)
end

---- lsp 回调函数快捷键设置
--pluginKeys.mapLSP = function(mapbuf)
--  -- rename
--  mapbuf("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opt)
--  -- code action
--  mapbuf("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opt)
--  -- go xx
--  mapbuf("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opt)
--  mapbuf("n", "gh", "<cmd>lua vim.lsp.buf.hover()<CR>", opt)
--  mapbuf("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opt)
--  mapbuf("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opt)
--  mapbuf("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opt)
--  -- diagnostic
--  mapbuf("n", "gp", "<cmd>lua vim.diagnostic.open_float()<CR>", opt)
--  mapbuf("n", "gk", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opt)
--  mapbuf("n", "gj", "<cmd>lua vim.diagnostic.goto_next()<CR>", opt)
--  mapbuf("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opt)
--  -- 没用到
--  -- mapbuf('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opt)
--  -- mapbuf("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opt)
--  -- mapbuf('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opt)
--  -- mapbuf('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opt)
--  -- mapbuf('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opt)
--  -- mapbuf('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opt)
--end

-- 列表快捷键
pluginKeys.nvimTreeList = {
    -- 打开文件或文件夹
    { key = { '<CR>', 'o', '<2-LeftMouse>' }, action = 'edit' },
    -- 分屏打开文件
    { key = 'v', action = 'vsplit' },
    { key = 'h', action = 'split' },
    -- 显示隐藏文件
    { key = 'i', action = 'toggle_custom' }, -- 对应 filters 中的 custom (node_modules)
    { key = '.', action = 'toggle_dotfiles' }, -- Hide (dotfiles)
    -- 文件操作
    { key = '<F5>', action = 'refresh' },
    { key = 'a', action = 'create' },
    { key = 'd', action = 'remove' },
    { key = 'r', action = 'rename' },
    { key = 'x', action = 'cut' },
    { key = 'c', action = 'copy' },
    { key = 'p', action = 'paste' },
    { key = 's', action = 'system_open' },
}

-- Telescope 列表中 插入模式快捷键
pluginKeys.telescopeList = {
    i = {
        -- 上下移动
        ['<C-j>'] = 'move_selection_next',
        ['<C-k>'] = 'move_selection_previous',
        ['<Down>'] = 'move_selection_next',
        ['<Up>'] = 'move_selection_previous',
        -- 历史记录
        ['<C-n>'] = 'cycle_history_next',
        ['<C-p>'] = 'cycle_history_prev',
        -- 关闭窗口
        ['<C-c>'] = 'close',
        -- 预览窗口上下滚动
        ['<C-u>'] = 'preview_scrolling_up',
        ['<C-d>'] = 'preview_scrolling_down',
    },
}

-- nvim-cmp 自动补全
pluginKeys.cmp = function(cmp)
    return {
        -- 出现补全
        ['<A-.>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
        -- 取消
        ['<A-,>'] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        -- 上一个
        ['<C-k>'] = cmp.mapping.select_prev_item(),
        -- 下一个
        ['<C-j>'] = cmp.mapping.select_next_item(),
        -- 确认
        ['<CR>'] = cmp.mapping.confirm({
            select = true,
            behavior = cmp.ConfirmBehavior.Replace,
        }),
        -- 如果窗口内容太多，可以滚动
        ['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
    }
end

-- typescript 快捷键
pluginKeys.mapTsLSP = function(mapbuf)
    mapbuf('n', 'gs', ':TSLspOrganize<CR>', opt)
    mapbuf('n', 'gr', ':TSLspRenameFile<CR>', opt)
    mapbuf('n', 'gi', ':TSLspImportAll<CR>', opt)
end

-- ToggleTerm 快捷键
pluginKeys.mapToggleTerm = function(toggleterm)
    vim.keymap.set({ 'n', 't' }, '<leader>ta', toggleterm.toggleA)
    vim.keymap.set({ 'n', 't' }, '<leader>tb', toggleterm.toggleB)
    vim.keymap.set({ 'n', 't' }, '<leader>tc', toggleterm.toggleC)
    vim.keymap.set({ 'n', 't' }, '<leader>tg', toggleterm.toggleG)
end
return pluginKeys
