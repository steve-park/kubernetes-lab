#!/bin/bash

# configure name resolution
echo "" >> /etc/hosts
echo "# Kubernetes Lab" >> /etc/hosts
echo "192.168.56.200    master" >> /etc/hosts
echo "192.168.56.201    worker-1" >> /etc/hosts
echo "192.168.56.202    worker-2" >> /etc/hosts
echo "192.168.56.203    worker-3" >> /etc/hosts
echo "192.168.56.210    storage" >> /etc/hosts

# configure kubernetes requirements
swapoff -a

rm -f /swap.img > /dev/null
cp /etc/fstab /etc/fstab.bak
egrep -v swap /etc/fstab.bak > /etc/fstab

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

systemctl stop ufw
systemctl disable ufw

# install & configure docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
do 
    NEEDRESTART_MODE=a apt-get remove -y $pkg 2> /dev/null
done

NEEDRESTART_MODE=a apt-get update

NEEDRESTART_MODE=a apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

NEEDRESTART_MODE=a apt-get update
NEEDRESTART_MODE=a apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker vagrant > /dev/null
systemctl enable docker.service > /dev/null
systemctl enable containerd.service > /dev/null

# set cgroup driver
mv /etc/containerd/config.toml /etc/containerd/config.toml.bak 2> /dev/null
sh -c "containerd config default" > /etc/containerd/config.toml
sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
# troubleshoot containerd error
cp /etc/containerd/config.toml /etc/containerd/config.toml.2
sed 's/disabled_plugins/#disabled_plugins/g' /etc/containerd/config.toml.2 > /etc/containerd/config.toml
rm -f /etc/containerd/config.toml.2 > /dev/null 2> /dev/null

systemctl restart containerd

# # install cri-dockerd
# # 2024.01.31 it causes 2-cri socket -> containd, cri-dockerd 
# # if you wish to use cri-docker, run "kubeadm init --cri-socket /var/run/cri-dockerd.sock"
# wget -qO- https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.9/cri-dockerd-0.3.9.amd64.tgz | tar xvz
# mv ./cri-dockerd/cri-dockerd /usr/local/bin/
# # mv ./cri-dockerd/cri-dockerd /usr/bin/
# rm -rf ./cri-dockerd/ > /dev/null 2> /dev/null

# wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service -O /etc/systemd/system/cri-docker.service
# wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket -O /etc/systemd/system/cri-docker.socket
# # mv cri-docker.socket cri-docker.service /etc/systemd/system/ 
# sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
# systemctl daemon-reload
# systemctl enable cri-docker.service
# systemctl enable --now cri-docker.socket
# systemctl status cri-docker.socket

# install & configure kubectl
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl bash-completion nfs-common
sudo apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet
systemctl start kubelet

# configure auto completion
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
echo "source <(kubeadm completion bash)" >> $HOME/.bashrc
echo 'source /usr/share/bash-completion/bash_completion' >> $HOME/.bashrc

# configure local persistent volume
mkdir -p /data/local-pv01
mkdir -p /data/local-pv02
mkdir -p /data/local-pv03