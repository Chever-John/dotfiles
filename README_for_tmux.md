# README for tmux

repeat-time 设置，主要用于禁用 tmux 中的重复按键功能。使用到的场景如下：

1. 避免误操作，某些场景下，用户可能会不小心连续按下某些键，导致执行不必要的命令。禁用重复按键功能可以减少这种误操作的可能性。
2. 精确控制，对于需要精确控制的用户，尤其是在复杂的 tmux 会话中，禁用重复按键可以确保每个命令都是经过明确意图触发的。

```conf
# disable the repeat key delay
set-option -g repeat-time 0
```
