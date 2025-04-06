# 针对 aliases 文件的优化脚本
DOTFILES_DIR="$HOME/.dotfiles/zsh/self-use"
ZSH_DIR="$HOME/.zsh"
ALIASES_SOURCE="$DOTFILES_DIR/aliases"
ALIASES_LINK="$ZSH_DIR/aliases"

# 创建目录，如果目录已存在，则跳过
mkdir -p "$DOTFILES_DIR"

# 复制 aliases 文件
cp "$HOME/.dotfiles/zsh/aliases" "$ALIASES_SOURCE"

# 检查链接文件是否存在，如果存在则删除
if [ -e "$ALIASES_LINK" ]; then
  rm -f "$ALIASES_LINK"
  echo "已删除旧的链接文件: $ALIASES_LINK"
fi

# 创建新的符号链接
ln -s "$ALIASES_SOURCE" "$ALIASES_LINK"
echo "创建新的符号链接: $ALIASES_LINK -> $ALIASES_SOURCE"

# 针对 envs 文件夹的优化脚本
ENVS_SOURCE="$DOTFILES_DIR/envs"
ENVS_LINK="$ZSH_DIR/envs"

# 复制 envs 文件夹
cp -r "$HOME/.dotfiles/zsh/envs" "$ENVS_SOURCE"

# 检查链接文件夹是否存在，如果存在则删除
if [ -e "$ENVS_LINK" ]; then
  rm -rf "$ENVS_LINK"
  echo "已删除旧的链接文件夹: $ENVS_LINK"
fi

# 创建新的符号链接
ln -s "$ENVS_SOURCE" "$ENVS_LINK"
echo "创建新的符号链接: $ENVS_LINK -> $ENVS_SOURCE"
