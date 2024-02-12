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

# install calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml -O
sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 172.16.0.0\/16/g' custom-resources.yaml
kubectl apply -f custom-resources.yaml
rm -f custom-resources.yaml > /dev/null 2> /dev/null

# install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployments metrics-server --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--kubelet-insecure-tls"}]'

# install MetalLB
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl diff -f - -n kube-system
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

# install nginx ingress controller for bare-metal
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml
kubectl -n ingress-nginx patch service ingress-nginx-controller --type='json' -p='[{"op": "replace", "path": "/spec/type", "value":"LoadBalancer"}]'

# install & configure longhorn
# kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.0/deploy/longhorn.yaml
wget -q https://raw.githubusercontent.com/longhorn/longhorn/v1.6.0/deploy/longhorn.yaml -O - | sed 's/numberOfReplicas: \"3/numberrOfReplicas: \"2/g' > ./longhorn-2.yaml
kubectl apply -f ./longhorn-2.yaml
kubectl -n longhorn-system patch service longhorn-frontend --type='json' -p='[{"op": "replace", "path": "/spec/type", "value":"LoadBalancer"}]'
rm -f ./longhorn-2.yaml > /dev/null 2> /dev/null

# install kustomize
mkdir -p /usr/local/bin
cd /usr/local/bin
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# install helm version 3
cd ~
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
