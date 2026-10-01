#!/bin/bash
# Debug wrapper for popup.sh: traces every tmux call into /tmp/tmux_debug_<ts>.log
LOG_FILE="/tmp/tmux_debug_$(date +%s).log"
exec 2>>"$LOG_FILE"
echo "session=$(tmux display-message -p '#{session_name}')" >>"$LOG_FILE"
bash -x ~/.dotfiles/tmux/popup.sh
tmux display-message "popup debug log: $LOG_FILE"
