#!/bin/bash
# This is an install script for all kubernetes boxes
# If you run into issues with swapoff, try restarting and then try again

#https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

apt update
apt upgrade -y


apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt update

apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

systemctl enable kubelet
systemctl start kubelet


# Install containerd/docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world

usermod -aG docker $USER

rm /etc/containerd/config.toml


swapoff -a

sudo kubeadm init --node-name controller01
