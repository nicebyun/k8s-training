#!/bin/bash

apt-get update
apt-get install -y git wget

# Install Docker
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common


#curl -fsSL get.docker.com | sh


curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

sudo cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update -y

sudo apt-get install -y  docker.io kubelet=1.13.2-00 kubeadm=1.13.2-00  kubectl=1.13.2-00  kubernetes-cni=0.6.0-00 nfs-common


sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo swapoff -a

sudo rm -rf /var/lib/kubelet/*

sudo apt-get install -y nfs-common bash-completion jq unzip
