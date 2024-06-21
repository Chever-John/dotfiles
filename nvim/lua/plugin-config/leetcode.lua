---@alias lc.lang
---| "cpp"
---| "java"
---| "python"
---| "python3"
---| "c"
---| "csharp"
---| "javascript"
---| "typescript"
---| "php"
---| "swift"
---| "kotlin"
---| "dart"
---| "golang"
---| "ruby"
---| "scala"
---| "rust"
---| "racket"
---| "erlang"
---| "elixir"
---| "bash"

local status, leetcode = pcall(require, 'leetcode')
if not status then
  vim.notify('没有找到 leetcode')
  return
end
leetcode.setup({
    ---@type string
    arg = "leetcode.nvim",

    ---@type lc.lang
    lang = "golang",

    cn = {
        enabled = true, ---@type boolean
        translator = true, ---@type boolean
        translate_problems = true, ---@type boolean
    },

    logging = true, ---@type boolean

    --- image_support = true, ---@type boolean 将此设置为 true 以禁用问题描述的换行

    
})
