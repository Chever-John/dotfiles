#!/bin/bash

echo "=== Mouse Support Diagnostic ==="
echo "Current TERM: $TERM"
echo "TMUX session: ${TMUX:-Not in tmux}"
echo ""

echo "=== Testing mouse capabilities ==="
echo "1. Check if terminal supports mouse:"
if command -v tput >/dev/null 2>&1; then
    if tput kmous >/dev/null 2>&1; then
        echo "   ✓ Terminal supports mouse"
    else
        echo "   ✗ Terminal may not support mouse"
    fi
else
    echo "   ? tput not available"
fi

echo ""
echo "2. Current terminal info:"
echo "   TERM: $TERM"
echo "   COLORTERM: ${COLORTERM:-not set}"
echo "   ALACRITTY_SOCKET: ${ALACRITTY_SOCKET:-not set}"

echo ""
echo "3. Tmux mouse settings (if in tmux):"
if [ -n "$TMUX" ]; then
    echo "   Mouse mode: $(tmux show-options -g mouse | cut -d' ' -f2)"
    echo "   Terminal overrides: $(tmux show-options -g terminal-overrides)"
else
    echo "   Not currently in tmux session"
fi

echo ""
echo "=== Recommendations ==="
echo "If you see escape sequences when clicking:"
echo "1. Make sure you're in a tmux session"
echo "2. Check terminal-overrides in tmux config"
echo "3. Verify TERM variable is correct"