#!/bin/bash

echo "🧪 Starting mouse test in tmux..."

# Kill any existing test session
tmux kill-session -t mouse-test 2>/dev/null

# Create new session with test content
tmux new-session -d -s mouse-test -c "$HOME"

# Send test content to the session
tmux send-keys -t mouse-test 'clear' Enter
tmux send-keys -t mouse-test 'echo "=== MOUSE TEST ==="' Enter
tmux send-keys -t mouse-test 'echo "Try the following:"' Enter
tmux send-keys -t mouse-test 'echo "1. Click anywhere to position cursor"' Enter
tmux send-keys -t mouse-test 'echo "2. Drag to select text"' Enter
tmux send-keys -t mouse-test 'echo "3. Right-click to paste selected text"' Enter
tmux send-keys -t mouse-test 'echo "4. Use mouse wheel to scroll"' Enter
tmux send-keys -t mouse-test 'echo "5. Click on pane borders to switch panes"' Enter
tmux send-keys -t mouse-test 'echo ""' Enter
tmux send-keys -t mouse-test 'cat /tmp/mouse-test.txt' Enter

# Split window for more testing
tmux split-window -h -t mouse-test
tmux send-keys -t mouse-test:0.1 'echo "Right pane - try clicking here!"' Enter
tmux send-keys -t mouse-test:0.1 'echo "Mouse should work in both panes"' Enter

# Select left pane
tmux select-pane -t mouse-test:0.0

echo "✅ Test session created!"
echo "🚀 Attach with: tmux attach -t mouse-test"
echo "🧹 Clean up with: tmux kill-session -t mouse-test"