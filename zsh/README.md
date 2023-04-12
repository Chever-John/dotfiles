# zsh 文件使用指南

当你开始看这个文件的时候，证明你准备在一台新的主机上安装 zsh 和 oh-my-zsh 这两个伟大的软件啦。所以让我们现在开始吧！

你肯定已经 `git clone` 好本仓库啦。如果没有请先 clone 到用户根目录下，然后重命名项目为 `.dotfile`。详细命令如下：

```bash
cd
git clone git@github.com:Chever-John/dotfiles.git
mv dotfiles .dotfiles
```

## 安装 oh-my-zsh && zsh

首先安装 oh-my-zsh。

### CentOS

```bash
yum install zsh -y
## 下面命令中的 root 换成你当前想要生效的用户名
chsh -s /bin/zsh root
echo $SHELL
## 如果 SHELL 没有更改，或许你需要退出当前会话

yum install wget git -y
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

rm ~/.zshrc
## 然后你需要首先软链将 `dotfiles/zsh/.zshrc` 文件到`~/.zshrc`
ln -s $HOME/.dotfiles/zsh/.zshrc ~/.zshrc

source ~/.zshrc
```

### Ubuntu

```bash
sudo apt install zsh -y
## 下面命令中的 root 换成你当前想要生效的用户名
chsh -s /bin/zsh root
echo $SHELL
## 如果 SHELL 没有更改，或许你需要退出当前会话

sudo apt install wget -y
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

rm ~/.zshrc
## 然后你需要首先软链将 `dotfiles/zsh/.zshrc` 文件到`~/.zshrc`
ln -s $HOME/.dotfiles/zsh/.zshrc ~/.zshrc

source ~/.zshrc
```

如果你想要一个标准的 `.zshrc` 文件的模版的话，可以运行如下命令：

```bash
/bin/cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
```

## 会有一个问题

当然，我们在进行操作的时候，难免会遇到各种各样的问题，这边我会记录一些我遇到的问题，以及解决方法。

## 遇到 antigen 插件找不到

其实就是上面执行命令中，下面这个命令执行失败了。

```bash
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
```

解决方法如下：

点击这个链接 <https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh>，然后将里面的内容复制到一个文件中，然后执行这个文件即可。

### autosuggestions 插件找不到

插件地址为 <https://github.com/zsh-users/zsh-autosuggestions>，途中遇到找不到的情况，解决方法如下

```bash
## 第一种方法
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

## 第二种方法
git clone git@github.com:zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

rm ~/.zshrc

source ~/.zshrc
```

## 别名文件：aliases

本文件夹还保存了一份 `.aliases` 文件，专门用来存储相关别名的设置。

```sh
ln -s $HOME/.dotfiles/zsh/aliases $HOME/.zsh/aliases
```

## 环境：envs

`envs` 文件存储了所有的环境变量。

```sh
ln -s $HOME/.dotfiles/zsh/envs $HOME/.zsh/envs
```
