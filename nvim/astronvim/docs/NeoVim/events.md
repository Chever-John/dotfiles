# NeoVim Events

这里总是有很多的 NeoVim Events，让我们来记录它。

- `BufWritePost`: 这个事件在缓冲区写入到文件之后触发。这意味着当用户保存文件时，某些插件比如说 `nvim-lint` 会执行代码检查。

- `BufReadPost`: 这个事件在缓冲区读取文件之后触发。这意味着当用户打开一个文件时，某些插件比如说 `nvim-lint` 会立即执行代码检查。

- `InsertLeave`: 这个事件在用户离开 插入模式时触发。这意味着当用户停止输入并切换到普通模式时，`nvim-lint` 会执行代码检查。

