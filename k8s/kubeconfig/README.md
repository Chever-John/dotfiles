# Kubernetes 的 kubeconfig 文件学习

在 k8s 中我们常使用一种 config 配置文件对集群进行控制，官方文档地址如[这里](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)。

最基本的一个 config 如下所示：

```yaml
apiVersion: v1
kind: Config

clusters:
- cluster:
    proxy-url: http://proxy.example.org:3128
    server: https://k8s.example.org/k8s/clusters/c-xxyyzz
  name: development

users:
- name: developer

contexts:
- context:
  name: development
```

