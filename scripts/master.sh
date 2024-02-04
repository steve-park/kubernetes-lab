#!/bin/bash

rm -rf /vagrant/config > /dev/null 2> /dev/null
rm -f /vagrant/scripts/worker.sh > /dev/null 2> /dev/null

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
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml -O
sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 172.16.0.0\/16/g' custom-resources.yaml
kubectl apply -f custom-resources.yaml
rm -f custom-resources.yaml > /dev/null 2> /dev/null

# install kustomize
mkdir -p /usr/local/bin
cd /usr/local/bin
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# install helm version 3
cd ~
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# create persistent volume
kubectl apply -f /vagrant/resources/pv-nfs.yaml
kubectl apply -f /vagrant/resources/pv-local.yaml