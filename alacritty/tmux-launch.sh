#!/bin/zsh
# alacritty 启动入口：
# - 主 session 没被占用 -> 接管它（等价于原来的 new-session -A）
# - 主 session 已被别的窗口占用 -> 复用空闲的编号 session，否则新建一个
# 这样 Cmd+N 开新窗口不会互相踢客户端（原来 -D 的问题）。

TMUX_BIN=/opt/homebrew/bin/tmux
BASE=CheverJohn_Always_Love_U

attached() {
  [ -n "$($TMUX_BIN list-clients -t "$1" 2>/dev/null)" ]
}

# 主 session 不存在或空闲 -> 直接用
if ! attached "$BASE"; then
  exec $TMUX_BIN new-session -A -s "$BASE"
fi

# 主 session 被占用 -> 找空闲的编号 session 复用，找不到就新建
i=2
while $TMUX_BIN has-session -t "${BASE}-${i}" 2>/dev/null; do
  attached "${BASE}-${i}" || exec $TMUX_BIN attach -t "${BASE}-${i}"
  i=$((i + 1))
done
exec $TMUX_BIN new-session -s "${BASE}-${i}"
