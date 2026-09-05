#!/usr/bin/env bash
# ==============================================================================
# Script 02: Multi-Stack Orchestrated Homelab Deployment
# ==============================================================================
# Purpose: Deploys all 4 core apps and foundational networking stacks sequentially
# ==============================================================================

set -euo pipefail

# Determine Homelab Base Directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==================================================================="
echo " Starting Homelab Deployment at: ${HOMELAB_DIR}"
echo "==================================================================="

# Verify .env exists
if [ ! -f "${HOMELAB_DIR}/.env" ]; then
  echo "[!] .env file not found. Copying .env.example to .env..."
  cp "${HOMELAB_DIR}/.env.example" "${HOMELAB_DIR}/.env"
  chmod 600 "${HOMELAB_DIR}/.env"
  echo "[!] Please review and edit '${HOMELAB_DIR}/.env' with your passwords, then rerun."
  exit 1
fi

# Load variables
set -a
# shellcheck disable=SC1091
source "${HOMELAB_DIR}/.env"
set +a

# 1. Ensure required data, media, and config directories exist
echo "[Step 1/4] Preparing directories..."
mkdir -p "${DATA_ROOT:-/opt/homelab/data}"/{pihole,dnsmasq.d,npm/data,npm/letsencrypt,memos,kavita,jellyfin/config,jellyfin/cache,immich/postgres}
mkdir -p "${MEDIA_ROOT:-/opt/homelab/media}"/{books,videos,music,photos}
mkdir -p "${HOMELAB_ROOT:-/opt/homelab}/backups"

# Ensure permissions
if [ -n "${PUID:-}" ] && [ -n "${PGID:-}" ]; then
  chown -R "${PUID}:${PGID}" "${DATA_ROOT:-/opt/homelab/data}" 2>/dev/null || true
  chown -R "${PUID}:${PGID}" "${MEDIA_ROOT:-/opt/homelab/media}" 2>/dev/null || true
fi

# 2. Ensure shared Docker network exists
echo "[Step 2/4] Ensuring Docker network 'homelab_net' exists..."
if ! docker network inspect homelab_net >/dev/null 2>&1; then
  docker network create --driver bridge homelab_net
  echo "[+] Network 'homelab_net' created."
else
  echo "[+] Network 'homelab_net' already active."
fi

# 3. Deploy stacks in sequence
echo "[Step 3/4] Deploying container stacks..."

STACKS=(
  "compose/01-network"
  "compose/02-dashboard"
  "compose/03-notes"
  "compose/04-books"
  "compose/05-media"
  "compose/06-photos"
)

for STACK in "${STACKS[@]}"; do
  STACK_PATH="${HOMELAB_DIR}/${STACK}/docker-compose.yml"
  if [ -f "${STACK_PATH}" ]; then
    echo " -> Launching [${STACK}]..."
    docker compose --env-file "${HOMELAB_DIR}/.env" -f "${STACK_PATH}" up -d
  else
    echo " [!] Warning: ${STACK_PATH} not found, skipping."
  fi
done

# 4. Summary Output
echo ""
echo "==================================================================="
echo " Deployment Complete! Active Services Summary:"
echo "==================================================================="
printf "%-24s | %-22s | %-16s\n" "Service" "URL (Direct Port)" "Subdomain"
printf "%-24s-+-%-22s-+-%-16s\n" "------------------------" "----------------------" "----------------"
printf "%-24s | %-22s | %-16s\n" "Homepage Dashboard" "http://${SERVER_IP}:3000" "dashboard.${DOMAIN_NAME}"
printf "%-24s | %-22s | %-16s\n" "Memos (Personal Notes)" "http://${SERVER_IP}:${MEMOS_PORT:-5230}" "notes.${DOMAIN_NAME}"
printf "%-24s | %-22s | %-16s\n" "Kavita (Ebooks/Comics)" "http://${SERVER_IP}:${KAVITA_PORT:-5000}" "books.${DOMAIN_NAME}"
printf "%-24s | %-22s | %-16s\n" "Jellyfin (Media Stream)" "http://${SERVER_IP}:${JELLYFIN_PORT:-8096}" "media.${DOMAIN_NAME}"
printf "%-24s | %-22s | %-16s\n" "Immich (Photos/Videos)" "http://${SERVER_IP}:${IMMICH_PORT:-2283}" "photos.${DOMAIN_NAME}"
printf "%-24s | %-22s | %-16s\n" "Pi-hole DNS Admin" "http://${SERVER_IP}:8080/admin" "dns.${DOMAIN_NAME}"
printf "%-24s | %-22s | %-16s\n" "Nginx Proxy Manager" "http://${SERVER_IP}:81" "proxy.${DOMAIN_NAME}"
echo "==================================================================="
echo " Verify running containers with: docker ps"
