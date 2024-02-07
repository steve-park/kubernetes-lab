#!/bin/bash

# install nfs-server
apt-get update
apt-get install -y nfs-kernel-server nfs-common acl

# configure nfs directory share
for name in static persistent transient registry
do
    mkdir -p /data/$name
    chmod 777 /data/$name
    # chown nobody:nogroup /data/$name    
    # setfacl -PRdm u::rwx,g::rwx,o::rwx /data/$name
done

echo "# Kubernetes Lab" >> /etc/exports
echo "/data/registry    *(rw,no_root_squash,insecure,sync,no_subtree_check)" >> /etc/exports
echo "/data/static      *(rw,no_root_squash,insecure,sync,no_subtree_check)" >> /etc/exports
echo "/data/persistent  *(rw,no_root_squash,insecure,sync,no_subtree_check)" >> /etc/exports
echo "/data/transient   *(rw,no_root_squash,insecure,sync,no_subtree_check)" >> /etc/exports

# configure firewall
# ufw allow from 192.168.56.0/24 to any port nfs
systemctl stop ufw
systemctl disable ufw

systemctl enable nfs-server
systemctl restart nfs-server