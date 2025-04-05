#!/bin/bash
# 保存为 ~/.dotfiles/tmux/debug-popup.sh

# 创建日志文件
LOG_FILE="/tmp/tmux_debug_$(date +%s).log"
echo "========== 开始调试会话 ==========" > $LOG_FILE

# 获取当前会话名称
SESSION_NAME=$(tmux display-message -p "#{session_name}")
echo "当前会话名称: $SESSION_NAME" >> $LOG_FILE

# 检查是否在 popup 会话中
if [ "$SESSION_NAME" = "popup" ]; then
    echo "情况1: 当前在 popup 会话中" >> $LOG_FILE
    tmux display-message "当前在 popup 会话中，准备分离"
    
    # 取消下面的注释以执行实际操作
    # tmux detach-client
else
    echo "情况2: 当前不在 popup 会话中" >> $LOG_FILE
    
    # 检查 popup 会话是否存在
    tmux has-session -t popup 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "popup 会话不存在，需要创建" >> $LOG_FILE
        tmux display-message "popup 会话不存在，准备创建"
        
        # 取消下面的注释以执行实际操作
        # tmux new-session -d -s "popup" "tmux source-file ~/.dotfiles/tmux/sessions/popup.tmux.conf"
    else
        echo "popup 会话已存在" >> $LOG_FILE
        tmux display-message "popup 会话已存在"
    fi
    
    echo "准备打开 popup 窗口" >> $LOG_FILE
    tmux display-message "准备打开 popup 窗口"
    
    # 取消下面的注释以执行实际操作
    # tmux display-popup -b rounded -h 90% -w 85% -E "tmux attach-session -t popup"
fi

echo "调试信息已写入: $LOG_FILE" >> $LOG_FILE
tmux display-message "调试完成，日志位置: $LOG_FILE"

