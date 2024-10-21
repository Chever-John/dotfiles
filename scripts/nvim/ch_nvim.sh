#!/bin/bash

# 定义选项
options=("InsisVim" "astrovim" "customvim")

# 显示提示信息
echo "准备将当前使用的 nvim，从以下选项中选择迁移到目标配置："
echo "1. InsisVim"
echo "2. astrovim"
echo "3. customvim"

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
mv ~/.local/share/nvim ~/.local/share/nvim.bak.$suffix
mv ~/.local/state/nvim ~/.local/state/nvim.bak.$suffix
mv ~/.cache/nvim ~/.cache/nvim.bak.$suffix
rm -rf ~/.config/nvim
ln -s ~/.dotfiles/nvim/$suffix2 ~/.config/nvim

echo "迁移已完成：从 $suffix 到 $suffix2。"
