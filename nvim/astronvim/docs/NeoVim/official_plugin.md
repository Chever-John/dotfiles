# 插件的基本配置

我发现配置基本有 `event`, `specs`, `opts` 和 `config` 这些配置。

结合 AstroNvim 的特性，说明一下这几个配置。

`event`: 这个配置项指定了 `nvim-lint` 插件加载的时机。`User AstroFile` 事件在 AstroNvim 的核心配置文件加载完成后触发。这样可以确保插件比如 `nvim-lint` 在 AstroNvim 完全初始化后再加载，避免潜在的冲突和性能问题，优化启动时间。
