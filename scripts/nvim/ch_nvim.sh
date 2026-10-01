#!/bin/bash

# 定义选项
options=("InsisVim" "AstroNvim" "CustomVim")

# 显示提示信息
echo "准备将当前使用的 nvim，从以下选项中选择迁移到目标配置："
echo "1. InsisVim"
echo "2. AstroNvim"
echo "3. CustomVim"

# 获取用户输入
read -p "请输入源配置的数字 (1, 2, 3): " source_choice
read -p "请输入目标配置的数字 (1, 2, 3): " target_choice

# 验证输入
if [[ $source_choice -lt 1 || $source_choice -gt 3 || $target_choice -lt 1 || $target_choice -gt 3 ]]; then
    echo "无效的选择，请输入 1, 2 或 3。"
    exit 1
fi

# 获取对应的配置名称
suffix=${options[$((source_choice-1))]}
suffix2=${options[$((target_choice-1))]}

# 执行命令
if [[ "$suffix" == "$suffix2" ]]; then echo "源和目标相同，无需迁移。"; exit 0; fi
if [[ ! -d ~/.dotfiles/nvim/$suffix2 ]]; then
    echo "目标配置 ~/.dotfiles/nvim/$suffix2 不存在（AstroNvim 可用: git clone https://github.com/Chever-John/AstroNvim.git ~/.dotfiles/nvim/AstroNvim）"
    exit 1
fi

# 备份当前数据目录（不存在就跳过；已有同名备份则加时间戳，避免 mv 进旧备份目录里）
backup() {
    local dir="$1" dest="$1.bak.$suffix"
    [[ -e "$dir" ]] || return 0
    [[ -e "$dest" ]] && dest="$dest.$(date +%Y%m%d%H%M%S)"
    mv "$dir" "$dest"
}
backup ~/.local/share/nvim
backup ~/.local/state/nvim
backup ~/.cache/nvim

# 恢复目标配置之前的数据（如果以前切走过）
for d in ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim; do
    [[ -d "$d.bak.$suffix2" ]] && mv "$d.bak.$suffix2" "$d"
done

if [[ -L ~/.config/nvim ]]; then rm -f ~/.config/nvim
elif [[ -e ~/.config/nvim ]]; then mv ~/.config/nvim ~/.config/nvim.bak."$(date +%Y%m%d%H%M%S)"; fi
mkdir -p ~/.config
ln -s ~/.dotfiles/nvim/$suffix2 ~/.config/nvim

echo "迁移已完成：从 $suffix 到 $suffix2。"
