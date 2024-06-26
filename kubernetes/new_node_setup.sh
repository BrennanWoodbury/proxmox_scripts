#!/usr/bin/bash
# to be used to setup a new kube node

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

if [ $# -lt 2 ]; then
  echo "Usage: $0 hostname ip"
  exit 1
fi

if [ $# -gt 2 ]; then
  echo "Usage: $0 hostname ip"
  exit 1
fi

trap ctrl_c INT
ctrl_c() {
  echo 'If you cancelled before rebooting, please ensure your system reboots or the ip and hostname changes will not go into effect.'
  exit 1
}

hostname=$1
ip=$2

hostnamectl hostname $1
sed -i 's/- 192\.168\.0\..*/$ip/24/' <file>

netplan apply

echo "System will reboot in 10 seconds, press Ctrl+C to cancel"
sleep 10
reboot

yes y | sh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
