# 如何配置 nvim

## Centos7 上的安装方法

不要尝试包括但不仅限于 `dnf`、`yum`的命令去安装 nvim，这是徒劳的。要知道对于 Centos7 这个感觉已经被世界抛弃了的版本来说，这些通用的包管理工具支持程度不高！

## 安装方法

进入到 nvim 的版本下载[地址](https://github.com/neovim/neovim/releases/tag/v0.7.2)，这边我选择下载 `Nvim v0.7.2` 版本。命令如下：

```bash
wget https://github.com/neovim/neovim/releases/download/v0.7.2/nvim-linux64.tar.gz
```

然后运行解压缩命令，命令如下：

```bash
tar -xvf nvim-linux64.tar.gz
```

然后直接找到里边的可执行文件，并配置好环境变量即可。

就是这么简单就好了，千万别想着去用 cmake 一类的工具自己编译（当然如果你有时间的话，另说）

## 配置文件

此处参考的是 YouTube 上

