# zsh 文件使用指南

当你开始看这个文件的时候，证明你准备在一台新的主机上安装 zsh 和 oh-my-zsh 这两个伟大的软件啦。所以让我们现在开始吧！

## 安装 oh-my-zsh && zsh

目前我常使用 Centos/Fedora、MacOS、Ubuntu 三种系统。且 Fedora 和 MacOS 已经成为我的默认开发工具。

### CentOS/Fedora

首先安装 oh-my-zsh。

```bash
yum install zsh -y
chsh -s /bin/zsh root
echo $SHELL
yum install wget git -y
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

source ~/.zshrc
```

如果你想要一个标准的 `.zshrc` 文件的模版的话，可以运行如下命令：

```bash
/bin/cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
```

但我坚持还是使用自己的祖传 zsh 呢。你需要首先软链将 `dotfiles/zsh/.zshrc` 文件到`~/.zshrc`。命令如下：

```bash
ln -s $HOME/.dotfiles/zsh/.zshrc ~/.zshrc
```

### MacOS

#### 第一步，安装 zsh

安装命令如下：

```sh
brew install zsh
```

如果没有安装 brew，可以访问这个[link](https://docs.brew.sh/Installation#:~:text=homebrew%2Dcore%20here-,/bin/bash%20%2Dc%20%22%24(curl%20%2DfsSL%20https%3A//raw.githubusercontent.com/Homebrew/install/master/install.sh)%22,-The%20default%20Git) 进行安装。

如果安装了之后还是找不到这个 brew，可以直接使用下面的命令：

```shell
/opt/homebrew/bin/brew update
```

#### 第二步，为当前用户设置 zsh 终端

设置命令如下：

```sh
chsh -s /bin/zsh $USER
echo $SHELL # 校验一下
```

#### 第三步，安装 oh-my-zsh

安装命令如下：

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### 第四步，创建 .zsh 文件夹

命令如下：

```sh
mkdir $HOME/.zsh
```

#### 第五步，创建别名文件 —— aliases

本文件夹还保存了一份 `.aliases` 文件，专门用来存储相关别名的设置。

```sh
ln -s $HOME/.dotfiles/zsh/aliases $HOME/.zsh/aliases
```

#### 第六步，创建环境文件 —— envs

`envs` 文件存储了所有的环境变量。

```sh
ln -s $HOME/.dotfiles/zsh/envs $HOME/.zsh/envs
```

#### 第七步，安装一些常用的软件

比如说 kubectl 这个工具，我最常用了。

##### 安装 kubectl

命令如下：

```sh
brew install kubectl
```

#### 最后，source ~/.zshrc

因为之前安装 oh-my-zsh 的时候，会给一个默认的 .zshrc 文件，所以我们这边第一个命令就是要删除它，完整命令如下：

```sh
rm -rf ~/.zshrc
```

#### 最最后一步，ln -s zshrc

我坚持还是使用自己的祖传 zsh 呢。你需要首先软链将 `dotfiles/zsh/.zshrc` 文件到`~/.zshrc`。命令如下：

```shell
ln -s $HOME/.dotfiles/zsh/.zshrc ~/.zshrc
source ~/.zshrc
```

## 可能遇到的问题

不过需要注意的是，你可能会遇到下面的问题

### autosuggestions 插件不奏效

可能会遇到 “[oh-my-zsh] plugin 'zsh-autosuggestions' not found” 这个报错信息。

我们可以直接操作官方的[仓库](https://github.com/zsh-users/zsh-autosuggestions)，解决方法如下：

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone git@github.com:zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

source ~/.zshrc
```

## 别名文件：aliases

本文件夹还保存了一份 `.aliases` 文件，专门用来存储相关别名的设置。

```sh
mkdir -r $HOME/.dotfiles/zsh/self-use/
cp $HOME/.dotfiles/zsh/aliases $HOME/.dotfiles/zsh/self-use
ln -s $HOME/.dotfiles/zsh/self-use/aliases $HOME/.zsh/aliases
```

## 环境：envs

`envs` 文件存储了所有的环境变量。

```sh
mkdir -r $HOME/.dotfiles/zsh/self-use/
cp $HOME/.dotfiles/zsh/envs $HOME/.dotfiles/zsh/self-use
ln -s $HOME/.dotfiles/zsh/envs $HOME/.zsh/envs
```
同样脚本放在最后：

```shell
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
```
