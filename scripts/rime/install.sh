#!/usr/bin/expect

# 设置临时目录和目标目录
set TMP_DIR "/tmp/rime-auto-deploy"
set DOTFILES_DIR "$env(HOME)/.dotfiles/rime"

# 如果临时目录已存在，则删除
if { [file exists $TMP_DIR] } {
    spawn rm -rf "$TMP_DIR"
    expect eof
}

# 克隆仓库
spawn git clone git@github.com:Mark24Code/rime-auto-deploy.git "$TMP_DIR"
expect eof

# 替换 custom 文件夹
if { [file isdirectory "$DOTFILES_DIR/custom"] } {
  spawn rm -rf "$TMP_DIR/custom"
  expect eof
  spawn cp -r "$DOTFILES_DIR/custom" "$TMP_DIR"
  expect eof
} else {
  puts "警告: $DOTFILES_DIR/custom 不存在，跳过替换"
}

# 进入临时目录
cd "$TMP_DIR"

# 运行 installer.rb 并处理交互
spawn ./installer.rb
expect eof  # 确保 ./installer.rb 启动完成

expect "Choose mode:"
send "2\r"

# 修改正则表达式，移除多余的 $ 符号
expect -re "\$$Handle Mode\$$.*Choose mode:"
send "4\r"
expect eof


puts "Rime 安装完成."
