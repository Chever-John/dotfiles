#!/bin/bash
# 新机器首次要做的事（Linux）。完整环境请直接跑 ~/.dotfiles/install.sh
sudo apt-get install -y git

git config --global user.name "Chever John"

git config --global user.email cheverjonathan@gmail.com

[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -C "cheverjonathan@gmail.com"

