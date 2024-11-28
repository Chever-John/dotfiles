--- 這個插件配置的前提是需要下載 macism、im-select
--- macos 上安裝的是 brew install macism 和 brew install im-select.
---@type LazySpec
return {
  "chaozwn/im-select.nvim",
  lazy = false,
  opts = {
    default_command = "macism",
    default_main_select = "im-selectim.rime.inputmethod.Squirrel.Hans",
    set_previous_events = { "InsertEnter", "FocusLost" },
  },
}
