# leetcode.nvim 插件

其实算法题目还是很有必要刷着玩的，可以提高我的日常思路！

所以我最近瞄准了这个项目 **leetcode.nvim**，当然这个 leetcode 是毋庸置疑的，大家都认识。

好了，就让我从这个话题开始慢慢展开聊这个 nvim 插件的配置。

## 插件配置

我所使用的插件配置管理工具是 Packer，最近好像听说 Lazy 比较火，但我觉得最适合的就是最好的吧。如果日后有必要更换，可以试一下，因为这个插件的官方文档里是没有 Packer 的配置的。当然我觉得这可能是认为我们开发者自然而然就知道的一些东西，所以就没有文档阐述。

这次关于这个插件的配置我所动到的文件如下：

```shell
plugins git:(feat/add-nvim-leetcode*)» git diff --name-only 866592a 30f74a2                             
nvim/init.lua
nvim/lua/plugin-config/leetcode.lua
nvim/lua/plugins.lua
```

所有文件的变更如下：

```shell
diff --git a/nvim/init.lua b/nvim/init.lua
index 208c9d8..463637f 100644
--- a/nvim/init.lua
+++ b/nvim/init.lua
@@ -22,6 +22,7 @@ require('plugin-config.telescope')
 require('plugin-config.dashboard')
 require('plugin-config.project')
 require('plugin-config.nvim-treesitter')
+require('plugin-config.leetcode')
 -- 内置LSP (新增)
 require('lsp.setup')
 require('lsp.cmp')
diff --git a/nvim/lua/plugin-config/leetcode.lua b/nvim/lua/plugin-config/leetcode.lua
new file mode 100644
index 0000000..5da0852
--- /dev/null
+++ b/nvim/lua/plugin-config/leetcode.lua
@@ -0,0 +1,42 @@
+---@alias lc.lang
+---| "cpp"
+---| "java"
+---| "python"
+---| "python3"
+---| "c"
+---| "csharp"
+---| "javascript"
+---| "typescript"
+---| "php"
+---| "swift"
+---| "kotlin"
+---| "dart"
+---| "golang"
+---| "ruby"
+---| "scala"
+---| "rust"
+---| "racket"
+---| "erlang"
+---| "elixir"
+---| "bash"
+
+local status, leetcode = pcall(require, 'leetcode')
+if not status then
+  vim.notify('没有找到 leetcode')
+  return
+end
+leetcode.setup({
+    ---@type string
+    arg = "leetcode.nvim",
+
+    ---@type lc.lang
+    lang = "golang",
+
+    cn = {
+        enabled = true, ---@type boolean
+    },
+
+    logging = true, ---@type boolean
+
+
+})
\ No newline at end of file
diff --git a/nvim/lua/plugins.lua b/nvim/lua/plugins.lua
index b27341e..9446673 100644
--- a/nvim/lua/plugins.lua
+++ b/nvim/lua/plugins.lua
@@ -40,6 +40,16 @@ packer.startup({
             end,
         })

+        --------------------- Special Function ---------------------------------------
+        use({
+            "kawre/leetcode.nvim",
+            requires = {
+              "nvim-telescope/telescope.nvim",
+              "nvim-lua/plenary.nvim",
+              "MunifTanjim/nui.nvim",
+            }
+        })
+
         -------------------------- Themes --------------------------------------------
         -- Colorschemes
         -- Description: This section focuses on the themes of nvim.
```

## 文件讲解

首先讲一下第一个文件，文件名如下：

```shell
nvim/init.lua
```

这个文件增加的代码如下：

```lua
require('plugin-config.leetcode')
```

意思是将这个 `lua/plugin-config/leetcode.lua` 文件给初始化了。

第二个文件，文件名如下：

```shell
nvim/lua/plugin-config/leetcode.lua
```

这个文件内容如下：

```lua
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
```

基本的配置了属于是，具体内容参照于[官方文档](https://github.com/kawre/leetcode.nvim/blob/master/lua/leetcode/config/template.lua)。

最后的配置，是 Packer 插件管理器的配置，这是最重要的，为了下载 `"kawre/leetcode.nvim" `这个插件。

如下：

```lua
+        --------------------- Special Function ---------------------------------------
+        use({
+            "kawre/leetcode.nvim",
+            requires = {
+              "nvim-telescope/telescope.nvim",
+              "nvim-lua/plenary.nvim",
+              "MunifTanjim/nui.nvim",
+            }
+        })
+
```

## 总结

还不错的体验，简单明了的。加油好好学习吧。
