# Karabiner 使用手册

嗯对了，使用这个，是因为我有一天遇到了 macOS 的离谱的一个问题。

Command+h 在 macOS 上是统一隐藏当前程序的快捷键。

然后有一天我突然想要折腾我的 alacritty+tmux 了。

然后我折腾到 tmux 的 popup 工作流了。

然后我的工作流其中 tmux 的代码如下：

```conf
# Ctrl+f, c:  运行 htop
bind h new-window -n 'htop' 'htop'

# Ctrl+f, k:  运行 kubectl top nodes
bind k new-window -n 'kubectl' 'kubectl top nodes'

# Ctrl+f, n:  运行 nmap
bind n new-window -n 'nmap' 'nmap -v localhost'

#  Ctrl+f, p: 运行 glances
bind p new-window -n 'glances' 'glances'
```
嗯对了，我想要使用 `Command+h` 来展示 htop 状态，快速展示就是说。

然后就遇到了这个问题了。

1. 我该如何避免让 `Command+h` 在 alacritty 上生效系统默认的功能（隐藏当前程序）呢？
2. 是否需要考虑兼容性。

## 实操

首先我下载了 karabiner 用来屏蔽 macOS 系统的 `Command+h` 按键。配置文件如下：

```json
{
    "description": "Block Command+H Hide in Alacritty and pass through to application",
    "manipulators": [
        {
            "conditions": [
                {
                    "bundle_identifiers": [
                        "^org\\.alacritty$"
                    ],
                    "type": "frontmost_application_if"
                }
            ],
            "from": {
                "key_code": "h",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [{ "key_code": "f20" }],
            "type": "basic"
        }
    ]
}
```

嗯对了，这段配置放置在 Karabiner-Elements 软件主界面的 `Complex Modifications` 的 `Add your own rule` 中。

配置作用很简单，就是说，如果我在 Alacritty 这个软件中，那么 `Command+h` 按键会修改成自动发送 `f20`（一个不存在的虚拟按键）。同样我接下来会在 alacritty 中配置 `f20`。

在 Alacritty 的 keybinding maps 中的配置如下:

```toml
# hotkey to open htop quickly
[[keyboard.bindings]]
chars = "\u0006h"
key = "F20"
```

意思很简单啦，tmux 的配置如下：

```conf
# Ctrl+f, h:  运行 htop
bind h new-window -n 'htop' 'htop'
```

## 完整按键流程分析

当你在 macOS 系统的 Alacritty 终端中按下 Command+h 后，会触发以下事件链：

1. 按键拦截阶段 (Karabiner-Elements)
首先，macOS 系统默认会将 Command+h 解释为"隐藏当前应用程序"的系统快捷键。但由于你安装了 Karabiner-Elements，它会先拦截这个按键事件。

根据你的 Karabiner 配置：

```json
{
    "description": "Block Command+H Hide in Alacritty and pass through to application",
    "manipulators": [
        {
            "conditions": [
                {
                    "bundle_identifiers": [
                        "^org\\.alacritty$"
                    ],
                    "type": "frontmost_application_if"
                }
            ],
            "from": {
                "key_code": "h",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [{ "key_code": "f20" }],
            "type": "basic"
        }
    ]
}
```
Karabiner-Elements 检测到该按键是在 Alacritty 应用中触发的（通过 bundle_identifiers 条件判断），于是将 Command+h 按键组合重新映射为 F20 功能键，从而阻止了 macOS 的默认"隐藏应用程序"行为。

2. 按键转换阶段 (Alacritty)
接下来，Alacritty 接收到了这个 F20 按键事件。根据你的 Alacritty 配置：

```toml
[[keyboard.bindings]]
chars = "\u0006h"
key = "F20"
```

Alacritty 将 F20 转换为字符序列 \u0006h：

\u0006 是 ASCII 控制字符，对应于 Ctrl+f
h 是字母 h
这意味着 Alacritty 会向其中运行的程序（在这里是 tmux）发送 Ctrl+f 然后是 h 的按键序列 。

3. 命令执行阶段 (tmux)
最后，tmux 接收到了这个按键序列。根据你的 tmux 配置：

```conf
# Ctrl+f, h:  运行 htop
bind h new-window -n 'htop' 'htop'
```

tmux 检测到 Ctrl+f 作为前缀键，然后接收到 h，于是执行绑定的命令：new-window -n 'htop' 'htop'。这个命令会创建一个名为 "htop" 的新窗口，并在其中运行 htop 程序。


