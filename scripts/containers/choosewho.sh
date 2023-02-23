#!/bin/bash
kubectl config view --minify

echo -n "Which cluster do you want to choose?
1 == docker-desktop
2 == vmware-k8s-cluster
3 == 130-test-cluster
4 == k8s-local
5 == devOps-cluster
6 == apisix-business-test
7 == apisix-business-dev
8 == apisix-business-sit

Please make your choice: "

read cluster
# if [ "$cluster" = 1 ];
# then
#         kubectl config --kubeconfig=configFromCheverJohn use-context 123-test-cluster
# else
#         kubectl config --kubeconfig=configFromCheverJohn use-context 130-test-cluster
# fi

case "$cluster" in
  1)
    kubectl config use-context docker-desktop
    ;;
  2)
    kubectl config use-context vmware-k8s-cluster
    ;;
  3)
    kubectl config use-context 130-test-cluster
    ;;
  4)
    kubectl config use-context k8s-local
    ;;
  5)
    kubectl config use-context devOps-Cluster
    ;;
  6)
    kubectl config use-context apisix-business-test
    ;;
  7)
    kubectl config use-context apisix-business-dev
    ;;
  8)
    kubectl config use-context apisix-business-sit
esac

