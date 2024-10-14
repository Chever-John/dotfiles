# NVIM

又爱又恨啊，被我自己之前的 [版本](./custom_nvim/README-zh.md) 给坑了，所以这次我决定重新来一遍。

总结了之前的问题，我过于纠结自己写一套完美的 lua 的 nvim 配置，从而导致很多情况下，没有能够及时跟进，所以我决定尝试使用成熟的 nvim 项目。我决定尝试：

1. [AstroNvim](https://docs.astronvim.com/);
2. [InsisVim](https://github.com/nshen/InsisVim)

目前先搞这两个，让我们开始吧！

## 首先试用一下 AstroNvim

一切根据官网配置，目前我搞了一套配置在这个文件当前目录下的 `astronvim` 文件夹中。

### 安装

首先复制配置，命令如下：

```shell
mv ~/.config/nvim ~/.config/nvim.bak
```

清理 neovim 的文件夹，命令如下：

```shell
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

clone 项目，当然我已经提前复制到我的 dotfiles 项目中了。命令如下：

```shell
git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
rm -rf ~/.config/nvim/.git
nvim
```

当然，我自己在 dotfiles 中也有，可以使用命令如下：

```shell
ln -s ~/.dotfiles/nvim/InsisVim ~/.config/nvim
```

