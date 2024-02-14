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
    },

    logging = true, ---@type boolean

    
})