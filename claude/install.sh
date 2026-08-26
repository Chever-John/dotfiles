#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./claude/install.sh [--force]

What it does:
  - Create ~/.claude if missing
  - Symlink reusable configs from this repo into ~/.claude:
      - CLAUDE.md
      - agents/
      - commands/
      - plugins/config.json
  - If ~/.claude/settings.json does NOT exist:
      - If $ANTHROPIC_AUTH_TOKEN is set, generate settings.json from settings.json.example and inject token
      - Else copy settings.json.example to ~/.claude/settings.json (with placeholder token)
  - If ~/.claude/plugins/known_marketplaces.json does NOT exist:
      - Copy plugins/known_marketplaces.json.example

Notes:
  - This script never overwrites existing files unless --force is provided.
EOF
}

FORCE=0
case "${1:-}" in
  --force) FORCE=1 ;;
  "" ) ;;
  -h|--help) usage; exit 0 ;;
  *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR"
DEST="${HOME}/.claude"
export SRC DEST

mkdir -p "$DEST"

link_path() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      rm -rf "$dest"
    else
      echo "Skip (exists): $dest" >&2
      return 0
    fi
  fi

  mkdir -p "$(dirname -- "$dest")"
  ln -s "$src" "$dest"
  echo "Linked: $dest -> $src"
}

copy_if_missing() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      rm -rf "$dest"
    else
      echo "Skip (exists): $dest" >&2
      return 0
    fi
  fi

  mkdir -p "$(dirname -- "$dest")"
  cp -R "$src" "$dest"
  echo "Copied: $dest <- $src"
}

# Stable, reusable assets (symlink)
link_path "$SRC/CLAUDE.md" "$DEST/CLAUDE.md"
link_path "$SRC/agents" "$DEST/agents"
link_path "$SRC/commands" "$DEST/commands"

mkdir -p "$DEST/plugins"
link_path "$SRC/plugins/config.json" "$DEST/plugins/config.json"

# settings.json (never commit secrets; generate locally)
if [[ ! -e "$DEST/settings.json" || "$FORCE" -eq 1 ]]; then
  if [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
    python3 - <<'PY'
import json, os
from pathlib import Path

src = Path(os.environ["SRC"]) / "settings.json.example"
dest = Path(os.environ["DEST"]) / "settings.json"

data = json.loads(src.read_text(encoding="utf-8"))
env = data.get("env") or {}
env["ANTHROPIC_AUTH_TOKEN"] = os.environ["ANTHROPIC_AUTH_TOKEN"]
data["env"] = env
dest.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Generated: {dest} (token injected from $ANTHROPIC_AUTH_TOKEN)")
PY
  else
    copy_if_missing "$SRC/settings.json.example" "$DEST/settings.json"
  fi
fi

# Optional plugin marketplace list (portable example)
if [[ ! -e "$DEST/plugins/known_marketplaces.json" || "$FORCE" -eq 1 ]]; then
  copy_if_missing "$SRC/plugins/known_marketplaces.json.example" "$DEST/plugins/known_marketplaces.json"
fi

echo "Done."


