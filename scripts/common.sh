#!/bin/bash

# configure name resolution
echo "" >> /etc/hosts
echo "# Kubernetes Lab" >> /etc/hosts
echo "192.168.56.200    master" >> /etc/hosts
echo "192.168.56.211    worker-1" >> /etc/hosts
echo "192.168.56.212    worker-2" >> /etc/hosts
echo "192.168.56.213    worker-3" >> /etc/hosts

# configure kubernetes requirements
swapoff -a

rm -f /swap.img > /dev/null
cp /etc/fstab /etc/fstab.bak
egrep -v swap /etc/fstab.bak > /etc/fstab

cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

systemctl stop ufw
systemctl disable ufw

# install & configure docker
apt-get update
apt-get remove -y docker docker-engine docker.io containerd runc

apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker vagrant

systemctl enable docker.service > /dev/null
systemctl enable containerd.service > /dev/null

# install & configure kubectl
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl bash-completion
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet
systemctl start kubelet

# configure auto completion
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
echo "source <(kubeadm completion bash)" >> $HOME/.bashrc
echo 'source /usr/share/bash-completion/bash_completion' >> $HOME/.bashrc

# configure local persistent volume
mkdir -p /data/pv01
mkdir -p /data/pv02
mkdir -p /data/pv03
mkdir -p /data/pv04
mkdir -p /data/pv05