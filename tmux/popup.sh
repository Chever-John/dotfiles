#!/bin/bash
# prefix + o: toggle a floating "popup" session for quick htop/glances/nmap checks.
# 在 popup 里再按 prefix + o（或 prefix + q）即关闭。

SESSION_NAME=$(tmux display-message -p "#{session_name}")

if [ "$SESSION_NAME" = "popup" ]; then
    tmux detach-client
else
    # 旧版本在这里连续 new-session 两次，第二次必然报 "duplicate session"
    if ! tmux has-session -t "=popup" 2>/dev/null; then
        tmux new-session -d -s "popup" -c "$HOME"
    fi
    tmux source-file ~/.dotfiles/tmux/sessions/popup.tmux.conf
    # 注意：popup 命令由 default-shell (zsh) 执行，zsh 会把开头的 =word 当成命令路径展开，所以 =popup 必须加引号
    tmux display-popup -b rounded -h 90% -w 85% -E "tmux attach-session -t '=popup'"
fi
