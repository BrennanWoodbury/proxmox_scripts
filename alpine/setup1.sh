#!/bin/ash

[ if $# -lt 2 ]; then
  echo "Command usage: $0 hostname ip"
  exit(1)
fi

hostname=$1
ip_address=$2

apk add git python3 net-tools sudo vim wget curl htop openssh ca-certificates iproute2 bind-tools nmap tmux lsof build-base unzip zip tar gzip bash util-linux sudo

adduser -D -g "" local_admin
echo "local_admin:wtpotusiotfampu" | chpasswd
addgroup sudo
adduser local_admin sudo
adduser local_admin wheel
echo "Added user \"local_admin\", created group \"sudo\" and added local_admin to both the \"sudo\" and \"wheel\" groups."

cp /etc/sudoers /etc/sudoers.bak
echo "%sudo ALL=(ALL:ALL) ALL" | EDITOR='tee -a' visudo

cp /etc/passwd /etc/passwd.bak
sed -i "s|^\(local_admin:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\)[^:]*|\1/bin/bash|" /etc/passwd
echo "set default shell to bash"

mkdir /home/local_admin/.ssh
chmod 700 /home/local_admin/.ssh

ssh-keygen -b  4096 -C $hostname@bwoody.local -f /home/local_admin/.ssh/id_rsa -N ""
echo "Created new ssh keypair @ /home/local_admin/.ssh/id_rsa*"

cat <<EOF >> /home/local_admin/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCd/zddBAhdJgoI6KbdKirO1jOQJa6ok5eC8OO+poVlVsjObNMWF6ptt04EiSZeeKQFnyz85UTPGwcoafcvM9+yfG1AcLFbfgaSHEkcgzAtT5dcnnb0FsH16cj4uh9UhsGcUTAJP1UWs+jASOlgMl9Uj7+Mpf8f1jJfdjhS/ZDyOn1jJV3CB7dxPIAjq1DRF8XaxTHI4M3zTQ0EpAR4qsGBJ4mwRRxkDtQbTXN33jbsoccJahX0KgbwK2MjAeYu+W/JeK+IT8hl7JsXSEEospuLE7H6RvvOwiuvT9izYHBx6gmpJZUMHaJnHjjutDy+hh3fQNDwM0WXV19EJ6KAnC5BYnIsjmVmao8Cb1XeTJDjxy2aXg57jfI9/wcoPsShwRs5KqaiDtwo7fzo+5CuQmYINcTu9PWa8OwCkne6IXCb8XUrgzPGcZ5pf/H1dIKqnMmxa8MwEyyT3DkNNiBSNS303tml2XkE5BFRyGtCLgYsXO1Yy+Y3vGVr8aHodd0Bo+8= bthedub@brennan_wsl
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDC4vf1lmQKXftCL6Q3zDJxo6M+TO6eelPJNmSePS3GT1qPm5j8jDbWInTRIAQwS8G32loOUfSA/6ikw+zYl6jFvGElM2j6KpLcBRWuL8l+moIeVcKuSpNxVXbjOm1fI9Xy9KcQiGlB0C2EAw74wa4EtusMJZA38UcvOQNa4iHnxODDDzkyigmBi6ri45CHiqyKtsU8DGK5qtGJBXsI07AVAGrhFK8ysOk3FyzlZDW6aqtRKkkWokUb7705RijCcft6IyQ7MCjz20ODobGjee6EsV+JbnKC4wqT/1LRB0/0yIYDOHgvZbRrG+RL1HPwwr663ggxEbpvjKdh91t3nJZ2haJB3bVLRC2I9rvOXeOhKdYoUkVznPXby6gnhxGuidJ6imZc6SL0Ym9Cd/oYEnT5RxrjB2Bb2HlO4jE+xypOjfgpDvZ05gGZMkKGheePcSFIkq4IErrqzJHMCu3Htu9Hkajc7HjYYpSTntrMFzUIAf3ODdpV1CII+hkKSPFSqfM= brenn@Brennans-Desktop
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0njhxy10VU0MN5Tre1tfXYXmHFEkl1itAR0nRnHON9DzX3sx6D9OGv5zJUuHyuEuHY1KkGlG/vbfRkoDLcqoZ3t30d5n4m0/E1BFLgRkweIBYCPQzDm1bDnFZDAM0NHLtD9UWVaAMLY7QOh/kk3ygMidQO1dIKyPYn4WH6EDRMjgB0Vdo5TGxNVW5g97XIwIrbO3VpbxenHsNr1bQ5Jm+rDYe+vnS9FFRdp72rI0tqGs4A06Jiq4+z+ajel00QwO5kvqyqBQocdRjcM3vP7R02LIsmJFTGhVCdcxybLRFsdkEJ1eARB8OYluVjgnUzeZc9jy7aUpaA/AYvvG4SUIa2OKzDcJabsiAYdWxaahwkHdk+4sSUby2Q4KDzs2xpx4vXr7JtcA49W8XQvo6RA4s/l8JMnopoVsKwUFyhgGWaqwn2At2hMnwWyylci69uRSVC89PZ/NxVjSCB1iEOvZoNYoTIgsWbwGGr7Jk/hgHD1cjGnmXVeuAHlA/foeifEGal4gNxqRLH600JMPXJ/QKm7XnyqEDZcLuSaZDoq7Qug/0Dq85gqe0G555fry20avaN9LPzhnt1G6CULUtJBeRnlvUcHOioTf/0VpUvjrk1H7VknzXcFP2fyozr0CvDKGK1okvgkuPJy0QdmNlwcB/qmLGHgbXASieK33iCybLlw== ansible@bwoody.local
EOF

echo "Updated ~/.ssh/id_rsa"

chown -R local_admin:local_admin /home/local_admin/.ssh
chmod 600 /home/local_admin/.ssh/authorized_keys

echo <<EOF >> /etc/network/interfaces 
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address $ip_address
  netmask 255.255.255.0
  gateway 192.168.0.1
EOF

echo "Updated eth0 to use IP $ip_address"
