#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)."
  exit 1
fi

# 1. Argument Validation
if [ $# -ne 1 ]; then
  echo "Usage: $0 hostname"
  exit 1
fi

hostname=$1
NEW_USER="local_admin"

# 2. System Updates & Base Packages
apt update && apt upgrade -y
apt install vim sudo acl ca-certificates jq unzip curl libatomic1 -y

# 3. Docker Installation
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Bitwarden Install + Automated Authentication & Password Fetch

# --- Skip FNM installation if it already exists ---
if [ -d "/opt/fnm" ]; then
    echo "fnm is already installed. Skipping installation."
else
    echo "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /opt/fnm --skip-shell
fi

# Always export paths so the running script can find fnm/node
export PATH="/opt/fnm:$PATH"
eval "$(fnm env --shell bash)"

# --- Skip Node 26 installation if it's already active ---
if command -v node &> /dev/null && [ "$(node -v | cut -d'.' -f1)" == "v26" ]; then
    echo "Node.js v26 is already installed. Skipping."
else
    echo "Installing Node.js v26..."
    fnm install 26
    fnm use 26
fi

# --- Skip Bitwarden CLI if 'bw' is already working ---
if command -v bw &> /dev/null; then
    echo "Bitwarden CLI is already installed. Skipping NPM install."
else
    echo "Installing Bitwarden CLI..."
    npm install -g @bitwarden/cli
    ln -sf "$(npm config get prefix)/bin/bw" /usr/local/bin/bw
fi

# --- AUTOMATED LOGIN & UNLOCK ---
bw login --apikey > /dev/null
export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)

PLAIN_PASS=$(bw get item "Local Admin Linux Password" --session "$BW_SESSION" | jq -r '.login.password')
unset BW_SESSION

if [ -z "$PLAIN_PASS" ] || [ "$PLAIN_PASS" == "null" ]; then
    echo "Error: Could not retrieve password from Bitwarden. Aborting."
    exit 1`
fi

# 5. User Creation & Group Provisioning
if id "$NEW_USER" &>/dev/null; then
    echo "User $NEW_USER already exists. Updating groups and password just in case..."
else
    echo "Creating user $NEW_USER..."
    useradd -m -s /bin/bash "$NEW_USER"
fi
echo "$NEW_USER:$PLAIN_PASS" | chpasswd
unset PLAIN_PASS # Clear immediately from memory

# Add to admin and docker groups
usermod -aG sudo "$NEW_USER"
usermod -aG docker "$NEW_USER"
echo "User $NEW_USER successfully created using Bitwarden credentials!"

# 6. SSH Directory and Key Generation
mkdir -p /home/$NEW_USER/.ssh
touch /home/$NEW_USER/.ssh/authorized_keys

ssh-keygen -b 4096 -C "$hostname@bwoody.internal" -f /home/$NEW_USER/.ssh/id_rsa -N ""
echo "Created new ssh keypair @ /home/$NEW_USER/.ssh/id_rsa*"

# Append authorized keys
cat <<EOF >> /home/$NEW_USER/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCd/zddBAhdJgoI6KbdKirO1jOQJa6ok5eC8OO+poVlVsjObNMWF6ptt04EiSZeeKQFnyz85UTPGwcoafcvM9+yfG1AcLFbfgaSHEkcgzAtT5dcnnb0FsH16cj4uh9UhsGcUTAJP1UWs+jASOlgMl9Uj7+Mpf8f1jJfdjhS/ZDyOn1jJV3CB7dxPIAjq1DRF8XaxTHI4M3zTQ0EpAR4qsGBJ4mwRRxkDtQbTXN33jbsoccJahX0KgbwK2MjAeYu+W/JeK+IT8hl7JsXSEEospuLE7H6RvvOwiuvT9izYHBx6gmpJZUMHaJnHjjutDy+hh3fQNDwM0WXV19EJ6KAnC5BYnIsjmVmao8Cb1XeTJDjxy2aXg57jfI9/wcoPsShwRs5KqaiDtwo7fzo+5CuQmYINcTu9PWa8OwCkne6IXCb8XUrgzPGcZ5pf/H1dIKqnMmxa8MwEyyT3DkNNiBSNS303tml2XkE5BFRyGtCLgYsXO1Yy+Y3vGVr8aHodd0Bo+8= bthedub@brennan_wsl
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDC4vf1lmQKXftCL6Q3zDJxo6M+TO6eelPJNmSePS3GT1qPm5j8jDbWInTRIAQwS8G32loOUfSA/6ikw+zYl6jFvGElM2j6KpLcBRWuL8l+moIeVcKuSpNxVXbjOm1fI9Xy9KcQiGlB0C2EAw74wa4EtusMJZA38UcvOQNa4iHnxODDDzkyigmBi6ri45CHiqyKtsU8DGK5qtGJBXsI07AVAGrhFK8ysOk3FyzlZDW6aqtRKkkWokUb7705RijCcft6IyQ7MCjz20ODobGjee6EsV+JbnKC4wqT/1LRB0/0yIYDOHgvZbRrG+RL1HPwwr663ggxEbpvjKdh91t3nJZ2haJB3bVLRC2I9rvOXeOhKdYoUkVznPXby6gnhxGuidJ6imZc6SL0Ym9Cd/oYEnT5RxrjB2Bb2HlO4jE+xypOjfgpDvZ05gGZMkKGheePcSFIkq4IErrqzJHMCu3Htu9Hkajc7HjYYpSTntrMFzUIAf3ODdpV1CII+hkKSPFSqfM= brenn@Brennans-Desktop
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0njhxy10VU0MN5Tre1tfXYXmHFEkl1itAR0nRnHON9DzX3sx6D9OGv5zJUuHyuEuHY1KkGlG/vbfRkoDLcqoZ3t30d5n4m0/E1BFLgRkweIBYCPQzDm1bDnFZDAM0NHLtD9UWVaAMLY7QOh/kk3ygMidQO1dIKyPYn4WH6EDRMjgB0Vdo5TGxNVW5g97XIwIrbO3VpbxenHsNr1bQ5Jm+rDYe+vnS9FFRdp72rI0tqGs4A06Jiq4+z+ajel00QwO5kvqyqBQocdRjcM3vP7R02LIsmJFTGhVCdcxybLRFsdkEJ1eARB8OYluVjgnUzeZc9jy7aUpaA/AYvvG4SUIa2OKzDcJabsiAYdWxaahwkHdk+4sSUby2Q4KDzs2xpx4vXr7JtcA49W8XQvo6RA4s/l8JMnopoVsKwUFyhgGWaqwn2At2hMnwWyylci69uRSVC89PZ/NxVjSCB1iEOvZoNYoTIgsWbwGGr7Jk/hgHD1cjGnmXVeuAHlA/foeifEGal4gNxqRLH600JMPXJ/QKm7XnyqEDZcLuSaZDoq7Qug/0Dq85gqe0G555fry20avaN9LPzhnt1G6CULUtJBeRnlvUcHOioTf/0VpUvjrk1H7VknzXcFP2fyozr0CvDKGK1okvgkuPJy0QdmNlwcB/qmLGHgbXASieK33iCybLlw== ansible@bwoody.local
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWabhCyxtSenx3Y5r/8KEY/nFxYyAZYIpqt3aFKKbO7
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAlLeVA4y8TyXrpMPaquKgU09WmFfYsFFgP0FqqXYQBc brennan@windows
EOF

# Ensure ownership and permissions for SSH are locked down
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
chmod 700 /home/$NEW_USER/.ssh
chmod 600 /home/$NEW_USER/.ssh/authorized_keys

# 7. Global Docker-Compose Directory Setup
mkdir -p /docker-compose
setfacl -R -d -m g:docker:rwx /docker-compose/
setfacl -R -m g:docker:rwx /docker-compose/

echo "Server setup complete for hostname: $hostname"