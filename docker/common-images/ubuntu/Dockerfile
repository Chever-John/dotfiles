FROM ubuntu:22.04
LABEL maintainer="<cheverjonathan@gmail.com>"

# 设置时区为上海
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 替换为清华大学的镜像源
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list 

# 更新软件包列表并安装所需工具
RUN apt-get update && \
    apt-get install -y netperf hping3 traceroute tcpdump dnsutils telnet && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*