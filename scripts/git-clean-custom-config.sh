#!/bin/bash
#
# Git Clean Filter for Custom Config Sections
# Author: Linus-style implementation - simple, robust, zero special cases
#
# This script removes lines between "# === BEGIN_CUSTOM_CONFIG === #" 
# and "# === END_CUSTOM_CONFIG === #" markers during git commits
# while preserving them in the working directory.

set -euo pipefail

# Read from stdin, process line by line
inside_custom_config=false

while IFS= read -r line; do
    case "$line" in
        "# === BEGIN_CUSTOM_CONFIG === #")
            inside_custom_config=true
            echo "$line"
            ;;
        "# === END_CUSTOM_CONFIG === #") 
            inside_custom_config=false
            echo "$line"
            ;;
        *)
            if [ "$inside_custom_config" = false ]; then
                echo "$line"
            fi
            ;;
    esac
done

# Handle case where stdin is empty or file doesn't end with newline
if [ "$inside_custom_config" = true ]; then
    echo "# === END_CUSTOM_CONFIG === #"
fi
