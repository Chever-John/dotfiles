#!/bin/bash
kubectl config view --minify

echo -n "Which cluster do you want to choose?
1 == docker-desktop
2 == vmware-k8s-cluster

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
esac

