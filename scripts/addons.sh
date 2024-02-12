#!/bin/bash

# configure MetalLB
kubectl apply -f /vagrant/resources/metallb.yaml

# install local docker registry
kubectl apply -f /vagrant/resources/docker-registry.yaml