# alacritty

这是一个很不错的工具。

我希望使用 alacritty + tmux + zsh + nvim（AstroNvim）来提高我的工作效率。

目前我的 alacritty keybindings 支持如下：

```shell
command+r  # 清屏，清理掉历史命令行的显示
command+w  # 隐藏，默认是直接quit了，这里改成隐藏
conmand+t  #新开窗口，假如需要第二个终端窗口
command+shfit+w #关闭当前窗口
command+delete #删除一行
command+f #搜索关键字
command+← #跳到行首
conmand+→ #跳到行尾
```

## 键绑定

每个键绑定都定义为一个对象，包含若干属性。大多数属性是可选的。对于字母键，`key` 属性的值应该是对应的字母，例如 `V`。功能键（如 F1, F2 等）也是类似的。主键盘上的数字键编码为 `Key1`, `Key2` 等。数字键盘上的键编码为 `Number1`, `Number2` 等。这些编码都与 `glutin::VirtualKeyCode` 枚举中的变体相匹配。

### 可用的 `key` 名称

所有可用的 `key` 名称可以在以下链接中找到：
[glutin::VirtualKeyCode 变体](https://docs.rs/glutin/*/glutin/enum.VirtualKeyCode.html#variants)

### `mods` 的可能值

- `Command` 或 `Super`：指的是超级键/命令键/Windows 键。
- `Control`：指的是控制键。
- `Shift`：指的是 Shift 键。
- `Alt` 和 `Option`：指的是 Alt/Option 键。

### 组合修饰键

修饰键可以通过 `|` 符号组合。例如，如果需要同时按下 Control 和 Shift 键，可以这样表示：

```yaml
mods: Control|Shift
```

## 快捷键说明

### tmux 相关

如果要实现 pane 切分分屏的效果：

```shell
Command + Shift + D # 水平切屏
Command + D # 左右切屏
```

获取 tmux 的 menu：

```shell
Command + a
```

切换 windows/server

就是下面如果有很多个 windows，可以使用下面快捷键切换：

```shell
Command + 1，2，3，4，5
```

如果要切换 上一个/下一个 windows，如下：

```shell
Command + [ or ]
```

