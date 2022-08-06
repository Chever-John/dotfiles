# 如何使用好本文件夹？

## 使用软链

我们可以直接使用软链接，将原本系统里的配置文件替换成这个文件夹里的配置文件。此处需要注意的是，因为一般性，我的 neovim 的配置文件 `init.vim` 位置处于 `~/.config/nvim/init.vim`。那么我只需要运行如下的软链接设置命令即可：

```bash
ln -s /nvim/init.vim ~/.config/nvim/init.vim
```

注意该命令运行位置在本项目的根目录下，请万分注意～

## 如何配置 nvim

### Centos7 上的安装方法

不要尝试包括但不仅限于 `dnf`、`yum`的命令去安装 nvim，这是徒劳的。要知道对于 Centos7 这个感觉已经被世界抛弃了的版本来说，这些通用的包管理工具支持程度不高！

### 安装方法

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

### 配置文件

此处参考的是 YouTube 上

### 可能存在的问题

你会遇到需要你 `Run ":checkhealth provider"` 的问题。这个问题的本质是你没有匹配好本地的 Python 版本，经过测试，python3.8.10 可以解决这个问题。解决方法如下：

1. 首先得到 Python3.8.10 的远吗安装包，命令如下：

```bash
wget https://www.python.org/ftp/python/3.8.10/Python-3.8.10.tgz
```

解压安装包，命令如下：

```bash
tar -xvf Python-3.8.10.tgz
```

进入到该压缩安装包，命令如下：

```bash
cd Python-3.8.10
```

2. 然后编译 Python，命令如下：

```bash
.configure
```

安装 Python，命令如下：

```bash
sudo make && sudo make install
```

3. 接下来需要安装pynvim 包，命令如下：

```bash
python3 -m pip install --user --upgrade pynvim
```

然后就解决问题了。
