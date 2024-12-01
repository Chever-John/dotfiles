# Pack-go

整个 pack-go.lua 的代码去看文件，我这边主要简单讲解一下。

整个文件氛围两个大部分。

## 第一部分

这一部分是一个函数的作用：

```lua
--TODO: https://github.com/golang/go/issues/60903
local set_mappings = require("astrocore").set_mappings

local function preview_stack_trace()
  local current_line = vim.api.nvim_get_current_line()
  local patterns_list = {
    "([^%s]+/[^%s]+%.go):(%d+)", -- 匹配文件路径和行号
  }

  local function try_patterns(patterns, line)
    for _, pattern in ipairs(patterns) do
      local filepath, line_nr = string.match(line, pattern)
      if filepath and line_nr then return filepath, tonumber(line_nr), 0 end
    end
    return nil, nil, nil
  end

  local filepath, line_nr, column_nr = try_patterns(patterns_list, current_line)
  if filepath then
    vim.cmd ":wincmd k"
    vim.cmd("e " .. filepath)
    vim.api.nvim_win_set_cursor(0, { line_nr, column_nr })
  end
end
```

**`preview_stack_trace`** 是主函数，包含了整个逻辑。

**`current_line = vim.api.nvim_get_current_line()`:** 获取当前光标所在行的文本内容。

**`patterns_list` 表:** 定义了一个 Lua 表，其中包含用于匹配文件路径和行号的正则表达式模式。目前只包含一个模式：`"([^%s]+/[^%s]+%.go):(%d+)"`。该模式用于匹配形如 `filepath.go:line_number` 的字符串。

- `([^%s]+/[^%s]+%.go)`: 匹配文件路径。`[^%s]+` 匹配一个或多个非空白字符，`/` 匹配路径分隔符，`%.go` 匹配以 `.go` 结尾的文件名。
- `(%d+)`: 匹配行号。`%d+` 匹配一个或多个数字。

**`try_patterns(patterns, line)` 函数:** 尝试使用 `patterns_list` 中的模式匹配给定的文本行 `line`。

- 遍历 `patterns` 表中的每个模式。
- 使用 `string.match(line, pattern)` 尝试匹配当前模式。如果匹配成功，则返回匹配到的文件路径、行号（转换为数字）和列号（默认为 0）。
- 如果所有模式都匹配失败，则返回 `nil, nil, nil`。

**`filepath, line_nr, column_nr = try_patterns(patterns_list, current_line)`:** 调用 `try_patterns` 函数，尝试匹配当前行的文本。

**条件判断 `if filepath then ... end`:** 如果匹配到文件路径，则执行以下操作：

- `vim.cmd ":wincmd k"`: 将光标移动到上方的窗口。这假设堆栈跟踪信息显示在下方窗口，而代码文件将在上方窗口打开。
- `vim.cmd("e " .. filepath)`: 在当前窗口打开匹配到的文件。
- `vim.api.nvim_win_set_cursor(0, { line_nr, column_nr })`: 将光标移动到指定行和列。

## 第二部分

开始完整配置整个返回的数据。

开始进行 `astrolsp` 插件配置，`opts = { config = { gopls = { ... } } }` 对这个插件进行配置选项。`config` 字段用于配置各个语言服务器，这里开始配置 `gopls`。

`on_attach = function(client, _) ... end`: `on_attach` 函数会在 `gopls` 语言服务器附加到缓冲区时被调用。该函数接受两个参数：`client` 表示语言服务器客户端，`_` 是一个占位符，表示第二个参数未使用。

## 额外知识

这里加一下额外的知识：

1. dap-repl

### dap-repl

`dap-repl` 指的是 Debug Adapter Protocol (DAP) 的 REPL (Read-Eval-Print Loop) 功能。它提供了一个交互式的调试环境，允许用户在调试过程中执行代码、检查变量值、以及与调试器进行交互。

**作用:**

- **执行代码:** 可以在 `dap-repl` 中输入任意代码并执行，这对于测试代码片段、修改变量值、或者调用函数非常有用。
- **检查变量:** 可以使用 `dap-repl` 打印变量的值，或者查看变量的详细信息。这有助于理解程序的状态，并找出错误的原因。
- **调用函数:** 可以在 `dap-repl` 中调用函数，并查看函数的返回值。
- **控制调试器:** 可以使用 `dap-repl` 中的命令控制调试器的行为，例如设置断点、单步执行、继续执行等。
- **语言特定功能:** 一些调试适配器还提供了语言特定的功能，例如 Python 的 `ipdb` 集成，可以在 `dap-repl` 中使用 `ipdb` 的所有功能。