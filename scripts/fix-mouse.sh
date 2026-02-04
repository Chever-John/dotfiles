#!/bin/bash

echo "🐭 Fixing Alacritty + tmux mouse support..."

# 1. Reload tmux configuration if in tmux
if [ -n "$TMUX" ]; then
    echo "📋 Reloading tmux configuration..."
    tmux source-file ~/.dotfiles/tmux/tmux.conf
    echo "✅ Tmux config reloaded"
else
    echo "ℹ️  Not in tmux session - config will apply on next tmux start"
fi

# 2. Test mouse support
echo ""
echo "🧪 Testing mouse support..."

# Check if we can enable mouse reporting
printf '\033[?1000h'  # Enable mouse reporting
printf '\033[?1002h'  # Enable cell motion mouse tracking
printf '\033[?1015h'  # Enable urxvt mouse mode
printf '\033[?1006h'  # Enable SGR mouse mode

echo "Mouse reporting enabled"

# 3. Instructions
echo ""
echo "🎯 Next steps:"
echo "1. If you're not in tmux, start a new tmux session:"
echo "   tmux new-session -s main"
echo ""
echo "2. If still having issues, try these tmux commands:"
echo "   tmux set -g mouse on"
echo "   tmux set -g terminal-overrides 'xterm*:smcup@:rmcup@'"
echo ""
echo "3. Test mouse functionality:"
echo "   - Click to position cursor"
echo "   - Drag to select text"
echo "   - Right-click to paste"
echo "   - Scroll wheel to scroll"

# 4. Create a test environment
echo ""
echo "🔧 Creating test environment..."
cat > /tmp/mouse-test.txt << 'EOF'
This is a test file for mouse functionality.
Try clicking on different words.
Try selecting text by dragging.
Try scrolling with the mouse wheel.
Try right-clicking to paste.

Line 1: The quick brown fox jumps over the lazy dog.
Line 2: Pack my box with five dozen liquor jugs.
Line 3: How vexingly quick daft zebras jump!
Line 4: The five boxing wizards jump quickly.
Line 5: Bright vixens jump; dozy fowl quack.
EOF

echo "Test file created at /tmp/mouse-test.txt"
echo "Open it with: cat /tmp/mouse-test.txt"