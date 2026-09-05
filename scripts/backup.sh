#!/usr/bin/env bash
# ==============================================================================
# Script: Automated Homelab Database & Config Backup
# ==============================================================================
# Purpose: Creates a daily timestamped compressed backup of:
# - Memos SQLite database
# - Immich PostgreSQL database
# - Application configurations (/opt/homelab/config)
# - Keeps the last 14 days of backups
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source .env
if [ -f "${HOMELAB_DIR}/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "${HOMELAB_DIR}/.env"
  set +a
fi

BACKUP_DIR="${HOMELAB_ROOT:-/opt/homelab}/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEMP_DUMP="${BACKUP_DIR}/dump_${TIMESTAMP}"

mkdir -p "${TEMP_DUMP}"

echo "[1/4] Dumping Immich PostgreSQL database..."
if docker ps | grep -q "hl_immich_postgres"; then
  docker exec -t hl_immich_postgres pg_dumpall -U "${IMMICH_DB_USER:-postgres}" > "${TEMP_DUMP}/immich_postgres.sql" || echo "[-] Immich pg_dump failed"
else
  echo "[*] hl_immich_postgres not running; skipping SQL dump."
fi

echo "[2/4] Backing up Memos SQLite database..."
if [ -f "${DATA_ROOT:-/opt/homelab/data}/memos/memos_prod.db" ]; then
  cp "${DATA_ROOT:-/opt/homelab/data}/memos/memos_prod.db" "${TEMP_DUMP}/memos.db"
fi

echo "[3/4] Packaging configurations..."
tar -czf "${BACKUP_DIR}/homelab_backup_${TIMESTAMP}.tar.gz" \
  -C "${HOMELAB_DIR}" config .env \
  -C "${TEMP_DUMP}" .

# Remove temp folder
rm -rf "${TEMP_DUMP}"

echo "[4/4] Pruning backups older than 14 days..."
find "${BACKUP_DIR}" -name "homelab_backup_*.tar.gz" -type f -mtime +14 -delete

echo "[+] Backup successfully created at: ${BACKUP_DIR}/homelab_backup_${TIMESTAMP}.tar.gz"
