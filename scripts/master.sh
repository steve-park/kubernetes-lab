#!/bin/bash

rm -rf /vagrant/config > /dev/null 2> /dev/null
rm -f /vagrant/scripts/worker.sh > /dev/null 2> /dev/null

# troubleshoot containerd error
cp /etc/containerd/config.toml /etc/containerd/config.toml.bak
sed 's/disabled_plugins/#disabled_plugins/g' /etc/containerd/config.toml.bak > /etc/containerd/config.toml
systemctl restart containerd

# create kubernetes cluster
kubeadm config images pull
kubeadm init --apiserver-advertise-address=192.168.56.200 --apiserver-cert-extra-sans=192.168.56.200 --pod-network-cidr=172.16.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# backup configuration
mkdir /vagrant/config > /dev/null 2> /dev/null
cp /etc/kubernetes/admin.conf /vagrant/config > /dev/null 2> /dev/null
cp /vagrant/resources/worker.txt /vagrant/scripts/worker.sh
kubeadm token create --ttl 24h0m0s --print-join-command >> /vagrant/scripts/worker.sh

# install Weave Net : version conflict with coredns
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=172.16.0.0/16"
# curl -L git.io/weave -o /usr/local/bin/weave
# chmod a+x /usr/local/bin/weave

# install calico
kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml

# install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployments metrics-server --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--kubelet-insecure-tls"}]'

# install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
kubectl apply -f /vagrant/resources/metallb.yaml

# install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/baremetal/deploy.yaml
kubectl -n ingress-nginx patch service ingress-nginx-controller --type='json' -p='[{"op": "replace", "path": "/spec/type", "value":"LoadBalancer"}]'

# create persistent volume
kubectl apply -f /vagrant/resources/pv.yaml

# install kustomize
mkdir -p /usr/local/bin
cd /usr/local/bin
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# install helm version 3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash