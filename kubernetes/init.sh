#!/usr/bin/bash

apt update
apt upgrade -y

apt install docker.io

systemctl start docker
systemctl enable docker

usermod -aG docker $USER

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt update

apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

systemctl enable kubelet
systemctl start kubelet

