#!/bin/bash

# install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployments metrics-server --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--kubelet-insecure-tls"}]'

# install MetalLB
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl diff -f - -n kube-system
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl apply -f /vagrant/resources/metallb.yaml

# install nginx ingress controller for bare-metal
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml
kubectl -n ingress-nginx patch service ingress-nginx-controller --type='json' -p='[{"op": "replace", "path": "/spec/type", "value":"LoadBalancer"}]'

# install csi-driver-nfs
# storage:/data/static : static manual persistent volume in subdirectory
# storage:/data/persistent : dynamic persistent volume for container with Retain Reclaim Policy : nfs-persistent
# storage:/data/trainsient : dynamic persistent volume for container with Delete Reclaim Policy : nfs-transient
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.6.0/deploy/install-driver.sh | bash -s v4.6.0 --
# curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.6.0/deploy/uninstall-driver.sh | bash -s v4.6.0 --
kubectl apply -f /vagrant/resources/csi-driver-nfs.yaml

# install local docker registry
# storage:/data/registry : static manual persistent volume for local docker registry
kubectl apply -f /vagrant/resources/registry.yaml