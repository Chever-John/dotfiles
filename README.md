# CheverJohn's dotfiles

[English](./README.md) | [中文](./README-zh.md)

## Background

This is the project I personally use to record information about my various profiles, remember not to copy my ha ~

https://www.baidu.com

try to solve the problem hint the link and jump to the link, but got failed.

## Install

Clone to `~/.dotfiles` (configs reference that path) and run the idempotent bootstrap:

```shell
git clone https://github.com/Chever-John/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh        # or: packages | tmux | tools | link | shell
```

Projects live under `~/workspace`. Go manages its own tool data (with
`GOPATH` defaulting to `~/go`); the installer does not create or manage
project directories.
