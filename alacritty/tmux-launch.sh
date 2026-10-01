#!/bin/zsh
# alacritty 启动入口：
# - 主 session 没被占用 -> 接管它（等价于原来的 new-session -A）
# - 主 session 已被别的窗口占用 -> 复用空闲的编号 session，否则新建一个
# 这样 Cmd+N 开新窗口不会互相踢客户端（原来 -D 的问题）。

# macOS 下 alacritty 从 Launchpad 启动时 PATH 很干净，所以优先找 Homebrew 的绝对路径
for TMUX_BIN in /opt/homebrew/bin/tmux /usr/local/bin/tmux /usr/bin/tmux; do
  [ -x "$TMUX_BIN" ] && break
done
BASE=CheverJohn_Always_Love_U

# 注意：tmux 的 -t 默认是前缀匹配，必须加 = 强制精确匹配，
# 否则 BASE 会误命中 BASE-2 这类编号 session。
attached() {
  [ -n "$($TMUX_BIN list-clients -t "=$1" 2>/dev/null)" ]
}

# 主 session 不存在或空闲 -> 直接用
if ! attached "$BASE"; then
  exec $TMUX_BIN new-session -A -s "$BASE"
fi

# 主 session 被占用 -> 找空闲的编号 session 复用，找不到就新建。
# new-session 带 -A：并发启动撞号时退化为镜像 attach，而不是报错退出关窗口。
i=2
while $TMUX_BIN has-session -t "=${BASE}-${i}" 2>/dev/null; do
  attached "${BASE}-${i}" || exec $TMUX_BIN attach -t "=${BASE}-${i}"
  i=$((i + 1))
done
exec $TMUX_BIN new-session -A -s "${BASE}-${i}"
