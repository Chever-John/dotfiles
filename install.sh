#!/usr/bin/env bash
# CheverJohn's dotfiles bootstrap (Linux / Ubuntu-first, macOS-aware). Idempotent.
#
#   ./install.sh            # everything
#   ./install.sh packages   # apt/brew packages
#   ./install.sh tmux       # build tmux from source if the system one is too old (Linux)
#   ./install.sh tools      # user-level tools (omz, fzf, nvim, kubectl, yazi, go, rust, bun...)
#   ./install.sh link       # symlink configs into $HOME
#   ./install.sh shell      # make zsh the login shell
#
# The repo is expected at ~/.dotfiles (all configs reference that path).
set -euo pipefail

DOT="$HOME/.dotfiles"
ARCH="$(uname -m)"; OS="$(uname -s)"
TMUX_VERSION="${TMUX_VERSION:-3.5a}"
GO_VERSION="${GO_VERSION:-go1.24.4}"        # keep in sync with zsh/envs
GO_INSTALL_DIR="$HOME/infra/dev-env/langs/go"
LOCAL_BIN="$HOME/.local/bin"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ok\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
gh_latest() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1; }
SUDO=""; [[ $EUID -ne 0 ]] && SUDO="sudo"

[[ "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" == "$DOT" ]] || {
  echo "Please clone this repo to $DOT (configs hard-reference that path)." >&2; exit 1; }
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

# --------------------------------------------------------------------------- packages
packages() {
  if [[ "$OS" == Darwin ]]; then
    log "brew packages"
    brew install zsh tmux tpm neovim fzf ripgrep fd yazi kubectl krew go htop glances nmap \
      translate-shell jq pipx alacritty || true
    return
  fi
  log "apt packages"
  $SUDO apt-get update -qq
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    zsh git curl wget unzip xz-utils tar gzip file jq gnupg \
    build-essential pkg-config bison autoconf automake libevent-dev libncurses-dev \
    htop glances nmap ripgrep fd-find translate-shell python3-venv python3-pip pipx
  # Debian names fd "fdfind"
  have fd || ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
  ok packages
}

# --------------------------------------------------------------------------- tmux
ver_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]; }
tmux_build() {
  [[ "$OS" == Darwin ]] && return 0
  local cur; cur="$(tmux -V 2>/dev/null | awk '{print $2}' || true)"
  # display-popup -b/-T, allow-set-title need >= 3.4
  if [[ -n "$cur" ]] && ver_ge "${cur//[a-z]/}" 3.4; then ok "tmux $cur"; return; fi
  log "building tmux $TMUX_VERSION (system has ${cur:-none})"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/tmux/tmux/releases/download/$TMUX_VERSION/tmux-$TMUX_VERSION.tar.gz" | tar xz -C "$tmp"
  ( cd "$tmp/tmux-$TMUX_VERSION" && ./configure --prefix=/usr/local >/dev/null && make -j"$(nproc)" >/dev/null && $SUDO make install >/dev/null )
  rm -rf "$tmp"; hash -r
  ok "$(/usr/local/bin/tmux -V)"
}

# --------------------------------------------------------------------------- tools
tools() {
  log "oh-my-zsh + plugins"
  [[ -d "$HOME/.oh-my-zsh" ]] || RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  local custom="$HOME/.oh-my-zsh/custom/plugins"
  for p in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    [[ -d "$custom/$p" ]] || git clone -q --depth 1 "https://github.com/zsh-users/$p" "$custom/$p"
  done

  log "tpm (tmux plugin manager)"
  [[ -d "$HOME/.tmux/plugins/tpm" ]] || git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

  log "fzf"
  if [[ ! -d "$HOME/.fzf" ]]; then git clone -q --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"; fi
  "$HOME/.fzf/install" --bin >/dev/null
  "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish >/dev/null
  ln -sf "$HOME/.fzf/bin/fzf" "$LOCAL_BIN/fzf"

  [[ "$OS" == Darwin ]] && { ok "tools (macOS: rest via brew)"; return; }

  log "neovim"
  if ! have nvim || ! ver_ge "$(nvim --version | head -1 | sed 's/NVIM v//;s/-.*//')" 0.11; then
    local nv="nvim-linux-x86_64"; [[ "$ARCH" == aarch64 ]] && nv="nvim-linux-arm64"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/$nv.tar.gz" | $SUDO tar xz -C /opt
    $SUDO rm -rf /opt/nvim && $SUDO mv "/opt/$nv" /opt/nvim
    $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  fi

  log "kubectl + krew"
  if ! have kubectl; then
    local kv; kv="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
    curl -fsSLo "$LOCAL_BIN/kubectl" "https://dl.k8s.io/release/$kv/bin/linux/amd64/kubectl" && chmod +x "$LOCAL_BIN/kubectl"
  fi
  if [[ ! -x "$HOME/.krew/bin/kubectl-krew" ]]; then
    local tmp; tmp="$(mktemp -d)"
    curl -fsSL https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz | tar xz -C "$tmp"
    "$tmp/krew-linux_amd64" install krew >/dev/null 2>&1; rm -rf "$tmp"
  fi

  log "yazi"
  if ! have yazi; then
    local tmp; tmp="$(mktemp -d)"
    curl -fsSLo "$tmp/y.zip" https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
    unzip -q "$tmp/y.zip" -d "$tmp"; install -m755 "$tmp"/yazi-*/yazi "$tmp"/yazi-*/ya "$LOCAL_BIN/"; rm -rf "$tmp"
  fi

  log "go ($GO_VERSION -> $GO_INSTALL_DIR/$GO_VERSION)"
  if [[ ! -x "$GO_INSTALL_DIR/$GO_VERSION/bin/go" ]]; then
    mkdir -p "$GO_INSTALL_DIR"; local tmp; tmp="$(mktemp -d)"
    curl -fsSL "https://go.dev/dl/$GO_VERSION.linux-amd64.tar.gz" | tar xz -C "$tmp"
    mv "$tmp/go" "$GO_INSTALL_DIR/$GO_VERSION"; rm -rf "$tmp"
  fi
  mkdir -p "$HOME/Workspace/golang" "$HOME/workspace"

  log "rust (rustup)"
  [[ -x "$HOME/.cargo/bin/cargo" ]] || curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path >/dev/null

  log "bun"
  # SHELL=/bin/sh stops the installer from appending to ~/.zshrc (zsh/envs already sets PATH)
  [[ -x "$HOME/.bun/bin/bun" ]] || { curl -fsSL https://bun.sh/install | SHELL=/bin/sh bash >/dev/null 2>&1; }

  log "wasmtime"
  if [[ ! -x "$HOME/.wasmtime/bin/wasmtime" ]]; then
    local tmp; tmp="$(mktemp -d)"
    curl -fsSL https://github.com/bytecodealliance/wasmtime/releases/latest/download/wasmtime-"$(gh_latest bytecodealliance/wasmtime)"-x86_64-linux.tar.xz | tar xJ -C "$tmp"
    mkdir -p "$HOME/.wasmtime/bin"; install -m755 "$tmp"/wasmtime-*/wasmtime "$HOME/.wasmtime/bin/"; rm -rf "$tmp"
  fi

  log "claude code CLI"
  if ! have claude; then
    # shellcheck disable=SC1091
    [[ -s "$HOME/.nvm/nvm.sh" ]] && . "$HOME/.nvm/nvm.sh"
    have npm && npm install -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
  fi
  ok tools
}

# --------------------------------------------------------------------------- link
link() {  # link SRC DEST (backs up real files once)
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then rm -f "$dest"
  elif [[ -e "$dest" ]]; then mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"; fi
  ln -s "$src" "$dest"; ok "$dest -> $src"
}
links() {
  log "linking configs"
  link "$DOT/zsh/.zshrc"          "$HOME/.zshrc"
  link "$DOT/tmux/tmux.conf"      "$HOME/.tmux.conf"
  link "$DOT/alacritty"           "$HOME/.config/alacritty"
  # aliases/envs: copied to zsh/self-use (keeps per-machine CUSTOM_CONFIG), linked into ~/.zsh
  bash "$DOT/scripts/zsh/deploy_envs_and_alias_file.sh"
  # nvim: AstroNvim user config lives at ~/.dotfiles/nvim/AstroNvim (see scripts/nvim/ch_nvim.sh)
  if [[ ! -d "$DOT/nvim/AstroNvim/.git" ]]; then
    mkdir -p "$DOT/nvim"
    git clone -q https://github.com/Chever-John/AstroNvim.git "$DOT/nvim/AstroNvim"
  fi
  [[ "$(readlink "$HOME/.config/nvim" 2>/dev/null)" == "$DOT/nvim/AstroNvim" ]] || link "$DOT/nvim/AstroNvim" "$HOME/.config/nvim"
  # Alacritty terminfo (harmless on servers; lets TERM=alacritty work over ssh)
  have tic && tic -x -o "$HOME/.terminfo" "$DOT/alacritty/terminfo.src" 2>/dev/null || true
  # Claude Code config
  bash "$DOT/claude/install.sh" || true
  # tmux plugins
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
}

# --------------------------------------------------------------------------- shell
shell() {
  local zsh; zsh="$(command -v zsh)"
  if [[ "$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || dscl . -read "/Users/$USER" UserShell | awk '{print $2}')" != "$zsh" ]]; then
    log "chsh -> $zsh"; $SUDO chsh -s "$zsh" "$USER"
  fi
  ok "login shell: $zsh"
}

case "${1:-all}" in
  packages) packages ;;
  tmux) tmux_build ;;
  tools) tools ;;
  link) links ;;
  shell) shell ;;
  all) packages; tmux_build; tools; links; shell ;;
  *) sed -n '2,12p' "$0"; exit 2 ;;
esac
