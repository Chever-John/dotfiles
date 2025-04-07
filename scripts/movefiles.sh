#!/bin/bash

# 源目录和目标目录
SRC_DIR="/Users/10027852/Downloads/golang从入门到通天/博客系统--代码"
DST_DIR="/Users/10027852/workspace/closedsource/github.com/Chever-John/golang-blog"

# 确保目标目录存在
mkdir -p "$DST_DIR"

# 检查源目录是否存在
if [ ! -d "$SRC_DIR" ]; then
    echo "错误: 源目录 $SRC_DIR 不存在!"
    exit 1
fi

echo "开始复制文件从 $SRC_DIR 到 $DST_DIR..."

# 使用cp命令复制文件，-r表示递归，-p保留文件属性
cp -rp "$SRC_DIR"/* "$DST_DIR"/

# 检查复制操作的结果
if [ $? -eq 0 ]; then
    echo "复制完成！"
    echo "共复制了 $(find "$SRC_DIR" -type f | wc -l) 个文件"
else
    echo "复制过程中发生错误!"
fi