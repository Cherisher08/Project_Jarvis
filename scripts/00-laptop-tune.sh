#!/usr/bin/env bash
# ==============================================================================
# Script 00: Laptop Hardware & Ubuntu Server OS Optimization
# ==============================================================================
# Purpose: Transform a 4GB RAM laptop into an always-on, memory-protected server
# - Prevents laptop from sleeping when the lid is closed
# - Configures ZRAM (compressed RAM) + a 4GB disk swapfile
# - Tunes kernel memory aggressiveness (vm.swappiness=15)
# - Disables WiFi power management if running on wireless
# ==============================================================================

set -euo pipefail

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this script with sudo: sudo ./00-laptop-tune.sh"
  exit 1
fi

echo "==================================================================="
echo " [Step 1/5] Configuring Laptop Lid & Power Management..."
echo "==================================================================="

# Backup logind.conf if not already backed up
if [ ! -f /etc/systemd/logind.conf.bak ]; then
  cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak
fi

# Configure systemd-logind to ignore lid closures
sed -i 's/^#\?HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
sed -i 's/^#\?HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
sed -i 's/^#\?HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
sed -i 's/^#\?LidSwitchIgnoreInhibited=.*/LidSwitchIgnoreInhibited=yes/' /etc/systemd/logind.conf

# Mask sleep and suspend targets so OS never enters standby
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 || true

# Restart logind to apply settings
systemctl restart systemd-logind
echo "[+] Lid close behavior configured: Laptop will stay awake when closed."

echo ""
echo "==================================================================="
echo " [Step 2/5] Configuring 4GB Swapfile..."
echo "==================================================================="

CURRENT_SWAP=$(free -m | awk '/Swap:/ {print $2}')
if [ "$CURRENT_SWAP" -lt 3000 ]; then
  echo "[*] Existing swap ($CURRENT_SWAP MB) is under 3GB. Provisioning 4GB /swapfile..."
  swapoff -a 2>/dev/null || true
  if [ -f /swapfile ]; then
    rm -f /swapfile
  fi
  fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  
  if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
  fi
  echo "[+] 4GB swapfile enabled."
else
  echo "[+] Existing swap ($CURRENT_SWAP MB) is sufficient."
fi

echo ""
echo "==================================================================="
echo " [Step 3/5] Installing & Activating ZRAM (RAM Compression)..."
echo "==================================================================="

apt-get update -qq
apt-get install -y -qq zram-tools

# Configure zram to compress with zstd using 50% of RAM
cat << 'EOF' > /etc/default/zramswap
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF

systemctl restart zramswap || true
echo "[+] ZRAM active: Memory compressed with zstd to protect against OOM."

echo ""
echo "==================================================================="
echo " [Step 4/5] Tuning Kernel Sysctl for 4GB Server Stability..."
echo "==================================================================="

cat << 'EOF' > /etc/sysctl.d/99-homelab-laptop.conf
# Keep swappiness low so fast RAM is preferred, but swap is ready
vm.swappiness=15
# Maintain a healthy filesystem directory/inode cache
vm.vfs_cache_pressure=50
# Network connection queue depth
net.core.somaxconn=1024
EOF

sysctl --system >/dev/null
echo "[+] Sysctl memory parameters applied."

echo ""
echo "==================================================================="
echo " [Step 5/5] Disabling WiFi Power Management (if wireless)..."
echo "==================================================================="

if [ -d /etc/NetworkManager/conf.d ]; then
  cat << 'EOF' > /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
[connection]
wifi.powersave = 2
EOF
  echo "[+] WiFi power save disabled via NetworkManager."
else
  echo "[*] NetworkManager not detected or Ethernet in use; skipping WiFi tuning."
fi

echo ""
echo "==================================================================="
echo " Laptop Server Optimization Complete! Your system is ready for Phase 1."
echo "==================================================================="
