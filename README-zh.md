# CheverJohn's dotfiles

[English](./README.md) | [中文](./README-zh.md)

## 描述

这是我个人用来记录自己各个配置文件信息的项目，切记不要照搬我的哈～

## 一键安装（Linux / macOS）

仓库必须放在 `~/.dotfiles`（所有配置都写死了这个路径）：

```shell
git clone https://github.com/Chever-John/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh            # 全部：packages -> tmux -> tools -> link -> shell
~/.dotfiles/install.sh link       # 只重新做软链
```

脚本是幂等的，可以重复运行。它会：

- 安装 zsh、htop/glances/nmap、ripgrep/fd、translate-shell 等（apt 或 brew）
- Linux 上系统 tmux < 3.4 时从源码编译 tmux（popup 的 `-b/-T`、`allow-set-title` 需要新版本）
- 安装 oh-my-zsh 及插件、tpm、fzf、neovim、kubectl+krew、yazi、Go、Rust、bun、wasmtime、Claude Code
- 软链 `~/.zshrc`、`~/.tmux.conf`、`~/.config/alacritty`、`~/.config/nvim`（AstroNvim）、`~/.claude/*`，
  并用 `scripts/zsh/deploy_envs_and_alias_file.sh` 部署 aliases/envs（本机专属配置写在
  `zsh/self-use/*` 的 `CUSTOM_CONFIG` 区块里，不进 git）
- 把登录 shell 改成 zsh

tmux 里 `prefix + | - C E G P S` 等弹窗用到的 `tmux-*` 命令在 `tmux/bin/` 下。

## 安装 tmux

## Alacrity 安装和配置

切记，**使用 brew 安装 alacritty**，命令如下：

```shell
brew install alacritty
```

相关文档在这个[位置](./alacritty/README.md)。

## ZSH 安装

当你第一次复制这个项目的时候。你最应该做的就是安装 zsh。

请参考 zsh 文件[指南](./zsh/README.md)

## NVIM 配置

系列文件请点击[这里](https://github.com/Chever-John/AstroNvim)

## Tmux 配置

tmux 使用指南请点击[这里](README_for_tmux.md)
