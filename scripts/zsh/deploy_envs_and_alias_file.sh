project="dotfiles" file="deploy_envs_and_alias_file.sh" version=1
#!/bin/bash

DOTFILES_DIR="$HOME/.dotfiles/zsh/self-use"
ZSH_DIR="$HOME/.zsh"
mkdir -p "$DOTFILES_DIR"

# 处理 aliases 文件
process_file() {
    local source_file="$1"
    local target_file="$2"
    local temp_file=$(mktemp)
    
    # 如果目标文件不存在，直接复制
    if [ ! -f "$target_file" ]; then
        cp "$source_file" "$target_file"
        echo "创建新文件: $target_file"
        return
    fi
    
    # 提取目标文件中的自定义配置部分
    local custom_config=""
    if grep -q "=== BEGIN_CUSTOM_CONFIG ===" "$target_file"; then
        custom_config=$(sed -n '/=== BEGIN_CUSTOM_CONFIG ===/,/=== END_CUSTOM_CONFIG ===/p' "$target_file")
    fi
    
    # 从源文件提取基础配置
    local basic_config=""
    if grep -q "=== BEGIN_BASIC_CONFIG ===" "$source_file"; then
        basic_config=$(sed -n '/=== BEGIN_BASIC_CONFIG ===/,/=== END_BASIC_CONFIG ===/p' "$source_file")
    else
        # 如果源文件没有标记，则视整个文件为基础配置
        basic_config=$(cat "$source_file")
        # 添加标记
        basic_config="# === BEGIN_BASIC_CONFIG === #\n${basic_config}\n# === END_BASIC_CONFIG === #"
    fi
    
    # 如果目标文件没有自定义配置部分，则添加模板
    if [ -z "$custom_config" ]; then
        custom_config="# === BEGIN_CUSTOM_CONFIG === #\n# 在这里添加机器特定的自定义配置\n# === END_CUSTOM_CONFIG === #"
    fi
    
    # 合并基础配置和自定义配置
    echo -e "${basic_config}\n\n${custom_config}" > "$temp_file"
    mv "$temp_file" "$target_file"
    echo "更新文件: $target_file (保留自定义配置)"
}

# 处理 aliases 文件
ALIASES_SOURCE="$HOME/.dotfiles/zsh/aliases"
ALIASES_TARGET="$DOTFILES_DIR/aliases"
process_file "$ALIASES_SOURCE" "$ALIASES_TARGET"

# 创建符号链接
ALIASES_LINK="$ZSH_DIR/aliases"
if [ -e "$ALIASES_LINK" ]; then
    rm -f "$ALIASES_LINK"
fi
ln -s "$ALIASES_TARGET" "$ALIASES_LINK"
echo "创建符号链接: $ALIASES_LINK -> $ALIASES_TARGET"

# 处理 envs 文件
# 如果 envs 是目录，则每个文件单独处理
if [ -d "$HOME/.dotfiles/zsh/envs" ]; then
    mkdir -p "$DOTFILES_DIR/envs"
    ENVS_SOURCE_DIR="$HOME/.dotfiles/zsh/envs"
    ENVS_TARGET_DIR="$DOTFILES_DIR/envs"
    
    # 遍历 envs 目录中的所有文件
    for file in $(find "$ENVS_SOURCE_DIR" -type f); do
        base_name=$(basename "$file")
        process_file "$file" "$ENVS_TARGET_DIR/$base_name"
    done
    
    # 创建符号链接
    ENVS_LINK="$ZSH_DIR/envs"
    if [ -e "$ENVS_LINK" ]; then
        rm -rf "$ENVS_LINK"
    fi
    ln -s "$ENVS_TARGET_DIR" "$ENVS_LINK"
    echo "创建符号链接: $ENVS_LINK -> $ENVS_TARGET_DIR"
else
    # 单个 envs 文件的情况
    ENVS_SOURCE="$HOME/.dotfiles/zsh/envs"
    ENVS_TARGET="$DOTFILES_DIR/envs"
    process_file "$ENVS_SOURCE" "$ENVS_TARGET"
    
    # 创建符号链接
    ENVS_LINK="$ZSH_DIR/envs"
    if [ -e "$ENVS_LINK" ]; then
        rm -f "$ENVS_LINK"
    fi
    ln -s "$ENVS_TARGET" "$ENVS_LINK"
    echo "创建符号链接: $ENVS_LINK -> $ENVS_TARGET"
fi
