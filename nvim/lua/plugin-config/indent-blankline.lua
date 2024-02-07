-- 首先是使用 pcall 函数来尝试加载 indent_blankline 插件，如果加载失败，就会返回一个错误信息，
-- 然后通过 vim.notify 函数来提示用户没有找到 indent_blankline 插件。
local status, ident_blankline = pcall(require('ibl'), "indent_blankline")
if not status then
    vim.notify('没有找到 indent_blankline')
    return
end

ident_blankline.setup({
    -- 空行占位，用于设置空行的占位字符
    space_char_blankline = ' ',
    -- 用 treesitter 判断上下文
    show_current_context = true,
    show_current_context_start = true,
    -- 用于设置上下文的模式，例如类、函数、方法等
    context_patterns = {
        'class',
        'function',
        'method',
        'element',
        '^if',
        '^while',
        '^for',
        '^object',
        '^table',
        'block',
        'arguments',
    },
    -- :echo &filetype
    filetype_exclude = {
        'dashboard',
        'packer',
        'terminal',
        'help',
        'log',
        'markdown',
        'TelescopePrompt',
        'lsp-installer',
        'lspinfo',
        'toggleterm',
    },
    -- 竖线样式
    -- char = '¦'
    -- char = '┆'
    -- char = '│'
    -- char = "⎸",
    char = '▏',
})
