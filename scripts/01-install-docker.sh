#!/usr/bin/env bash
# ==============================================================================
# Script 01: Official Docker CE & Compose Plugin Installation
# ==============================================================================
# Purpose: Sets up Docker Engine with automated container log rotation
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this script with sudo: sudo ./01-install-docker.sh"
  exit 1
fi

echo "==================================================================="
echo " [Step 1/3] Removing legacy packages & adding Docker official repo..."
echo "==================================================================="

apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq

echo ""
echo "==================================================================="
echo " [Step 2/3] Installing Docker CE, CLI & Docker Compose Plugin..."
echo "==================================================================="

apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ""
echo "==================================================================="
echo " [Step 3/3] Configuring Docker Log Rotation Daemon & User Group..."
echo "==================================================================="

# Restrict container log files so they never fill up the laptop disk
mkdir -p /etc/docker
cat << 'EOF' > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# Add invoking non-root user to docker group if SUDO_USER is set
if [ -n "${SUDO_USER:-}" ]; then
  usermod -aG docker "$SUDO_USER"
  echo "[+] User '$SUDO_USER' added to the 'docker' group."
fi

echo ""
echo "==================================================================="
echo " Docker installation complete! Version installed:"
docker --version
docker compose version
echo " Note: Run 'newgrp docker' or log out and back in to use docker without sudo."
echo "==================================================================="
