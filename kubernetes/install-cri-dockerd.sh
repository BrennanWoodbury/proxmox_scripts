#!/bin/bash
# This uses v 3.14 releaed in may of 2024, update based on your needs

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.14/cri-dockerd-0.3.14.amd64.tgz

tar -xvf cri-dockerd-0.3.14.amd64.tgz

mv cri-dockerd/cri-dockerd /usr/local/bin/

cat <<EOF | sudo tee /etc/systemd/system/cri-docker.service
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
Wants=network-online.target
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/cri-dockerd --container-runtime-endpoint fd://
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF


cat <<EOF | sudo tee /etc/systemd/system/cri-docker.socket
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service

[Socket]
ListenStream=/run/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF


systemctl daemon-reload
systemctl enable cri-docker.service 
systemctl enable cri-docker.socket
systemctl start cri-docker.service
systemctl start cri-docker.socket

usermod -aG docker $USER

echo "###### INSTALL FINISHED ######" 
echo "check that cri-docker is working by running"
echo " - sudo systemctl status cri-docker.service"
echo " - sudo docker run hello-world"
echo "Troubleshoot as necessary" 
