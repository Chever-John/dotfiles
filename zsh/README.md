# zsh 文件使用指南

当你开始看这个文件的时候，证明你准备在一台新的主机上安装 zsh 和 oh-my-zsh 这两个伟大的软件啦。所以让我们现在开始吧！

首先你肯定已经 `git clone` 好本仓库啦。然后你需要首先软链将 `dotfiles/zsh/.zshrc` 文件到`~/.zshrc`。命令如下：

```bash
ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
```

## 安装 oh-my-zsh && zsh

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

## 会有一个问题

### autosuggestions 插件不奏效

https://github.com/zsh-users/zsh-autosuggestions，解决方法如下

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

source ~/.zshrc
```

