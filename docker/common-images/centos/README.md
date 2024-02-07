# ubuntu 镜像

这一款镜像，主要还是用来给我自己做一些常用的工作的事情。

比如说我要测试网络插件之间的性能，我可以使用这个我魔改的镜像，立刻运行，然后去获取我想要知道的网络参数。

| 版本  | 版本内容                                     |      |
| ----- | -------------------------------------------- | ---- |
| v1    | 能用就行                                     |      |
| v2/v3 | 能用就行                                     |      |
| v4    | 添加 <br />1. traceroute；<br />2. tcpdump。 |      |

## 运行命令

在 macOS 上运行的命令如下：

```shell
docker run --name=chever_test -it --rm cheverjohn/chever_centos_v8_macos:test bash
```

在 Linux 上运行的命令如下：

```shell
docker run --name=chever_test -it --rm cheverjohn/chever_centos_v8_linux:test bash
```

