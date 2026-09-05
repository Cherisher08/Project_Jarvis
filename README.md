# 4GB RAM Laptop HomeLab (Ubuntu Server)

A clean, modular, and memory-optimized home lab built for a **4GB RAM Laptop** running **Ubuntu Server 22.04/24.04 LTS (Headless)**.

Features 4 core self-hosted services, a central documentation dashboard, and secure zero-trust remote access via Tailscale and Pi-hole DNS:

1. 📸 **Photo & Video Backup**: [Immich](https://immich.app/) (Lean profile without machine-learning bloat)
2. 🎬 **Media Streaming**: [Jellyfin](https://jellyfin.org/) (Direct Play & music/video library)
3. 📚 **Ebook & Comic Library**: [Kavita](https://www.kavitareader.com/) (EPUB, PDF, CBZ with OPDS feed)
4. 📝 **Personal Notes**: [Memos](https://usememos.com/) (Google Keep alternative with tags, checklists & PWA)
5. 📊 **Unified Dashboard & Portal**: [Homepage](https://gethomepage.dev/) (Live health monitoring & embedded docs)
6. 🛡️ **Network & Privacy**: [Pi-hole](https://pi-hole.net/) (DNS ad-blocking) + [Nginx Proxy Manager](https://nginxproxymanager.com/) + [Tailscale](https://tailscale.com/)

---

## Repository Structure

```
├── compose/
│   ├── 01-network/           # Pi-hole + Nginx Proxy Manager
│   ├── 02-dashboard/         # Homepage Dashboard
│   ├── 03-notes/             # Memos (Personal Notes)
│   ├── 04-books/             # Kavita (Ebooks)
│   ├── 05-media/             # Jellyfin (Media Streaming)
│   └── 06-photos/            # Immich Lean (Photos & Videos)
├── config/
│   ├── homepage/             # Dashboard settings, live widgets & bookmarks
│   └── pihole/               # Custom DNS records
├── scripts/
│   ├── 00-laptop-tune.sh     # Lid ignore, ZRAM compression & swap tuning
│   ├── 01-install-docker.sh  # Official Docker CE & Compose plugin installer
│   ├── 02-deploy-all.sh      # Orchestrated deployment runner
│   └── backup.sh             # Automated database & configuration backup
├── docs/
│   ├── ARCHITECTURE.md       # Memory budget, port matrix & network model
│   ├── DASHBOARD_GUIDE.md    # Dashboard customization & navigation
│   └── ADDING_NEW_APPS.md    # Low-level model SOP for adding containers
├── .env.example              # Centralized environment variables template
└── README.md                 # This master guide
```

---

## Step-by-Step Deployment Guide

### Phase 0: Prepare & Tune the Laptop OS
Laptops will enter sleep mode when the lid is closed and easily freeze if physical RAM runs out. Run the tuning script to apply lid-ignore rules, enable ZRAM memory compression, and set up a 4GB disk swapfile:

1. Log into your Ubuntu Server terminal via SSH.
2. Clone or copy this repository to `/opt/homelab`:
   ```bash
   sudo git clone <YOUR_REPO_URL> /opt/homelab
   cd /opt/homelab
   ```
3. Make scripts executable and run the laptop tuning script:
   ```bash
   chmod +x scripts/*.sh
   sudo ./scripts/00-laptop-tune.sh
   ```

---

### Phase 1: Install Docker & Configure Remote Access (Tailscale)

1. Run the Docker installation script:
   ```bash
   sudo ./scripts/01-install-docker.sh
   newgrp docker
   ```
2. Set up Tailscale VPN for secure worldwide access without opening router ports:
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```
3. Authenticate using the link displayed in your terminal. Note down your laptop's Tailscale IP (e.g., `100.x.y.z`).

---

### Phase 2: Configure Environment & Secrets

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   chmod 600 .env
   ```
2. Edit `.env` to configure your passwords and your server IP:
   ```bash
   nano .env
   ```
   - Set `SERVER_IP` to your laptop's static LAN IP (or Tailscale IP).
   - Set `TZ` to your local timezone (e.g. `America/New_York` or `Asia/Kolkata`).
   - Change `PIHOLE_PASSWORD` and `IMMICH_DB_PASSWORD`.

---

### Phase 3: Launch All Services

Launch all stacks sequentially with healthchecks:
```bash
./scripts/02-deploy-all.sh
```

---

## Service Directory & Access Matrix

Once deployed, access each service directly via port or through clean `.home.lab` subdomains:

| Service | Port Access | Subdomain | Role & Notes |
| :--- | :--- | :--- | :--- |
| **📊 Homepage Dashboard** | `http://<SERVER_IP>:3000` | `dashboard.home.lab` | Central homelab portal with live status |
| **📝 Memos Notes** | `http://<SERVER_IP>:5230` | `notes.home.lab` | Google Keep clone with checklists & tags |
| **📚 Kavita Ebooks** | `http://<SERVER_IP>:5000` | `books.home.lab` | Ebook/comic reader with OPDS feed |
| **🎬 Jellyfin Streaming** | `http://<SERVER_IP>:8096` | `media.home.lab` | Movies, TV shows & music streaming |
| **📸 Immich Photos** | `http://<SERVER_IP>:2283` | `photos.home.lab` | Mobile photo auto-backup (Lean mode) |
| **🛡️ Pi-hole DNS** | `http://<SERVER_IP>:8080/admin` | `dns.home.lab` | Network DNS sinkhole & local name resolver |
| **🌐 Nginx Proxy Manager** | `http://<SERVER_IP>:81` | `proxy.home.lab` | Web reverse proxy & SSL certificate manager |

> **Default NPM Admin Login**: `admin@example.com` / `changeme` (Change immediately upon initial login!)

---

## Automated Backups

To back up your databases (Memos SQLite + Immich PostgreSQL) and configuration files:
```bash
./scripts/backup.sh
```
To run this automatically every night at 3:00 AM, add a cron job:
```bash
crontab -e
# Add line:
0 3 * * * /opt/homelab/scripts/backup.sh >/dev/null 2>&1
```

---

## Expanding Your Homelab

Need to add a new container? Consult [docs/ADDING_NEW_APPS.md](file:///d:/Projects/HomeLab/docs/ADDING_NEW_APPS.md) for the standard 3-step process.
