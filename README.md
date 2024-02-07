# kubernetes-lab
build multi-node kubernetes lab environment using vagrant

## Node Infromation
* Storage : NFS Server for PersistentVolume
* Master : Kubernetes Master Node
* Worker-N : Kubernetes Worker Node

## Directory Information
* resources : provisioning scripts resources
* scripts : provisioning scripts
* config : kubernetes admin config

## Installed Addons
* [Calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/)
* [MetalLB](https://metallb.universe.tf)
* [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
* [metrics-server](https://github.com/kubernetes-sigs/metrics-server)
* [Kustomize](https://kustomize.io)
* [Helm](https://helm.sh)
* [k9s](https://k9scli.io)
* [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs)
