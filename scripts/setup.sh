#!/bin/bash
# ==============================================================================
# HOME LAB SYSTEM - Ubuntu Server Post-Install Setup Script
# ==============================================================================
# This script automates the installation of:
#   1. Cockpit (Web-based server administration)
#   2. Docker Engine & Docker Compose plugin (Native Linux container runtime)
#   3. Tailscale VPN (Secure zero-configuration remote access)
#   4. Disables systemd-resolved (frees port 53 for Pi-hole DNS container)
# And sets up the base directories under /opt/homelab with correct permissions.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Clear screen
clear
echo "========================================================================"
echo "          HOME LAB SYSTEM - UBUNTU SERVER INITIAL SETUP SCRIPT          "
echo "========================================================================"
echo "This script will install Cockpit, Docker, Tailscale, and build the"
echo "directory structure at /opt/homelab/ for all home lab modules."
echo "========================================================================"
echo ""

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] ERROR: This script must be run with sudo privileges."
  echo "    Please run: sudo $0"
  exit 1
fi

# Detect the actual non-root user running sudo
ACTUAL_USER=${SUDO_USER:-$USER}
if [ "$ACTUAL_USER" = "root" ]; then
  echo "[!] WARNING: You are running directly as root."
  echo "    Volume permissions will be mapped to root (UID 0)."
  echo "    It is highly recommended to run this with 'sudo' from a standard user."
  read -p "Do you want to continue? (y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# 1. Update and Upgrade Ubuntu Packages
echo "[*] Updating package repositories..."
apt-get update

echo "[*] Installing prerequisite utility packages..."
apt-get install -y ca-certificates curl gnupg lsb-release git

# 2. Install Cockpit Server Dashboard
echo "[*] Installing Cockpit Server Dashboard..."
apt-get install -y cockpit
echo "[*] Enabling and starting Cockpit service..."
systemctl enable --now cockpit.socket

# 3. Install Docker Engine and Docker Compose Plugin
echo "[*] Setting up Docker repository keys..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
chmod a+r /etc/apt/keyrings/docker.gpg

echo "[*] Adding Docker repository to sources list..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[*] Updating repositories with Docker listings..."
apt-get update

echo "[*] Installing Docker Engine & Docker Compose Plugin..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
if [ "$ACTUAL_USER" != "root" ]; then
  echo "[*] Adding user '$ACTUAL_USER' to the docker group..."
  usermod -aG docker "$ACTUAL_USER"
  echo "[+] User '$ACTUAL_USER' added to docker group."
fi

# 4. Disable systemd-resolved (frees up port 53 for Pi-hole DNS container)
# Ubuntu Server 22.04 runs systemd-resolved which binds to port 53 by default.
# Pi-hole requires exclusive ownership of port 53 to serve DNS to the network.
echo "[*] Disabling systemd-resolved to free port 53 for Pi-hole..."
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Replace /etc/resolv.conf with a static DNS configuration
# (During setup, use Google DNS temporarily — Pi-hole will take over after deploy)
rm -f /etc/resolv.conf
cat > /etc/resolv.conf << 'EOF'
# Temporary DNS for setup — will be replaced by Pi-hole after deployment
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
chattr +i /etc/resolv.conf   # Prevent NetworkManager from overwriting it
echo "[+] systemd-resolved disabled. Port 53 is now free for Pi-hole."

# 5. Install Tailscale VPN
echo "[*] Installing Tailscale VPN..."
curl -fsSL https://tailscale.com/install.sh | sh
echo "[+] Tailscale installed successfully."

# 6. Create Homelab Folder Structure
echo "[*] Creating folder structure under /opt/homelab..."

# Base data directories
mkdir -p /opt/homelab/config/compose
mkdir -p /opt/homelab/photos
mkdir -p /opt/homelab/recordings
mkdir -p /opt/homelab/media
mkdir -p /opt/homelab/books
mkdir -p /opt/homelab/homeassistant
mkdir -p /opt/homelab/backups
mkdir -p /opt/homelab/pihole

# Phase 1 — Foundation service config dirs
mkdir -p /opt/homelab/config/portainer_data
mkdir -p /opt/homelab/config/nginx_proxy_manager/data
mkdir -p /opt/homelab/config/nginx_proxy_manager/letsencrypt

# Phase 2 — Network service config dirs
mkdir -p /opt/homelab/config/pihole/etc-pihole
mkdir -p /opt/homelab/config/pihole/etc-dnsmasq.d
mkdir -p /opt/homelab/config/unbound
mkdir -p /opt/homelab/config/ntfy

# Phase 3 — Camera service config dirs
mkdir -p /opt/homelab/config/frigate

# Phase 4 — Smart Home service config dirs
mkdir -p /opt/homelab/config/mosquitto/data
mkdir -p /opt/homelab/config/mosquitto/log
mkdir -p /opt/homelab/homeassistant


# Permissions
USER_UID=$(id -u "$ACTUAL_USER")
USER_GID=$(id -g "$ACTUAL_USER")

echo "[*] Setting /opt/homelab ownership to $ACTUAL_USER (UID: $USER_UID, GID: $USER_GID)..."
chown -R "$USER_UID":"$USER_GID" /opt/homelab

echo "========================================================================"
echo "[+] POST-INSTALLATION SETUP COMPLETED SUCCESSFULLY!"
echo "========================================================================"
echo ""
echo "1. Cockpit Web UI: http://YOUR_SERVER_IP:9090"
echo "   (Log in using your Ubuntu username and password)"
echo ""
echo "2. Tailscale: Enable VPN by running: sudo tailscale up"
echo "   (Follow the link output in the terminal to authenticate)"
echo ""
echo "3. Docker Permissions: Please LOG OUT and LOG BACK IN"
echo "   (or run: newgrp docker) to run docker commands without sudo."
echo ""
echo "4. systemd-resolved is DISABLED. Port 53 is reserved for Pi-hole."
echo "   DNS is temporarily pointed to 1.1.1.1 until Pi-hole is deployed."
echo ""
echo "5. Ready for configuration files. Copy your Compose configs to:"
echo "   /opt/homelab/config/"
echo ""
echo "========================================================================"
