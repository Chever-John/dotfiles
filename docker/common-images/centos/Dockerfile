FROM centos:8
LABEL maintainer="<cheverjonathan@gmail.com>"

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
      echo "Asia/Shanghai" > /etc/timezone && \
      sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
      sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum update -y && \
      yum install -y epel-release && \
      yum install -y netperf && \
      yum install -y hping3 traceroute tcpdump bind-utils telnet && \
      yum clean all
