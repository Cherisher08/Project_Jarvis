# HomeLab System Architecture & Design Specification

This document defines the underlying system architecture, network model, memory budget, and port allocation for the **4GB RAM Laptop Ubuntu Server** homelab.

---

## 1. System Philosophy & Design Constraints

1. **Hardware Profile**: 4GB Physical RAM laptop running headless Ubuntu Server 22.04 / 24.04 LTS.
2. **Resource Budgeting**: Every single Docker container must have explicit memory constraints (`deploy.resources.limits.memory`) to prevent runaway memory leaks from triggering the Linux Out-Of-Memory (OOM) killer.
3. **No Camera / Heavy ML Load**: Security camera video streams (RTSP) and computer vision/CLIP machine-learning models are excluded to conserve RAM and CPU cycles.
4. **Zero Open Public Ports**: Tailscale VPN is used for all remote access. No port forwarding is required or permitted on your home router.

---

## 2. Memory Budget (4,096 MB Total RAM)

| Service Layer | Container Name | Baseline RAM | Hard Limit | Storage Path |
| :--- | :--- | :--- | :--- | :--- |
| **Host OS + ZRAM** | Systemd / Kernel | ~450 MB | N/A | `/` |
| **Tailscale VPN** | Host systemd daemon | ~35 MB | N/A | `/var/lib/tailscale` |
| **Pi-hole DNS** | `hl_pihole` | ~60 MB | 150 MB | `/opt/homelab/data/pihole` |
| **Nginx Proxy Manager** | `hl_nginx_proxy_manager` | ~120 MB | 250 MB | `/opt/homelab/data/npm` |
| **Homepage Dashboard** | `hl_homepage` | ~60 MB | 120 MB | `/opt/homelab/config/homepage` |
| **Memos (Notes)** | `hl_memos` | ~35 MB | 80 MB | `/opt/homelab/data/memos` |
| **Kavita (Ebooks)** | `hl_kavita` | ~160 MB | 300 MB | `/opt/homelab/data/kavita` |
| **Jellyfin (Media)** | `hl_jellyfin` | ~400 MB | 750 MB | `/opt/homelab/data/jellyfin` |
| **Immich Server** | `hl_immich_server` | ~380 MB | 512 MB | `/opt/homelab/media/photos` |
| **Immich Postgres** | `hl_immich_postgres` | ~180 MB | 256 MB | `/opt/homelab/data/immich/postgres` |
| **Immich Redis** | `hl_immich_redis` | ~25 MB | 64 MB | In-memory |
| **Safety Cache / Buffer** | Linux File Cache | ~1,000+ MB | N/A | N/A |
| **Total Steady State** | **All 7 stacks running** | **~1.9 - 2.3 GB** | **~2.48 GB Max** | - |

---

## 3. Network Architecture & DNS Resolution

```
[ Family Phone / Laptop / Tablet ]
           │
           │ (Encrypted WireGuard Mesh)
           ▼
[ Tailscale IP: 100.x.y.z ] OR [ Local LAN IP: 192.168.1.50 ]
           │
           ├── Port 53 (UDP/TCP) ────► [ Pi-hole DNS ] (Resolves *.home.lab)
           │
           ├── Port 80 / 443 ────────► [ Nginx Proxy Manager ]
           │                                 │
           │                                 ├── dashboard.home.lab ──► Port 3000 (Homepage)
           │                                 ├── notes.home.lab ──────► Port 5230 (Memos)
           │                                 ├── books.home.lab ──────► Port 5000 (Kavita)
           │                                 ├── media.home.lab ──────► Port 8096 (Jellyfin)
           │                                 ├── photos.home.lab ─────► Port 2283 (Immich)
           │                                 ├── dns.home.lab ────────► Port 8080 (Pi-hole Web)
           │                                 └── proxy.home.lab ──────► Port 81 (NPM Admin)
```

---

## 4. Port Allocation Matrix

| Service | Container Internal Port | Host Published Port | Subdomain (`*.home.lab`) | Protocol |
| :--- | :--- | :--- | :--- | :--- |
| **Nginx Proxy Manager HTTP** | 80 | `80` | All web traffic | HTTP |
| **Nginx Proxy Manager HTTPS** | 443 | `443` | All encrypted traffic | HTTPS |
| **Nginx Proxy Manager Admin** | 81 | `81` | `proxy.home.lab` | HTTP |
| **Pi-hole DNS Query** | 53 | `53` | N/A | TCP/UDP |
| **Pi-hole Web Admin** | 80 | `8080` | `dns.home.lab` | HTTP |
| **Homepage Dashboard** | 3000 | `3000` | `dashboard.home.lab` | HTTP |
| **Memos (Google Keep clone)**| 5230 | `5230` | `notes.home.lab` | HTTP |
| **Kavita (Ebook Reader)** | 5000 | `5000` | `books.home.lab` | HTTP |
| **Jellyfin Media Streaming** | 8096 | `8096` | `media.home.lab` | HTTP |
| **Immich Photo/Video Core** | 2283 | `2283` | `photos.home.lab` | HTTP |
| **Immich PostgreSQL** | 5432 | Internal only (`immich_postgres`) | N/A | TCP |
| **Immich Valkey/Redis** | 6379 | Internal only (`immich_redis`) | N/A | TCP |

---

## 5. Directory & File Storage Topology

```
/opt/homelab/
├── .env                      # Global environment and secrets (chmod 600)
├── .env.example              # Documented variable template
├── compose/                  # Isolated docker-compose definitions
│   ├── 01-network/           # Pi-hole + NPM
│   ├── 02-dashboard/         # Homepage
│   ├── 03-notes/             # Memos
│   ├── 04-books/             # Kavita
│   ├── 05-media/             # Jellyfin
│   └── 06-photos/            # Immich (Lean)
├── config/                   # Editable configurations
│   ├── homepage/             # Dashboard settings, services, widgets
│   └── pihole/               # Custom DNS lists
├── data/                     # Read-write application database state
│   ├── pihole/
│   ├── npm/
│   ├── memos/
│   ├── kavita/
│   ├── jellyfin/
│   └── immich/
├── media/                    # Bulk user assets
│   ├── books/                # EPUBs, PDFs, CBR/CBZ comics
│   ├── videos/               # Movies and TV show libraries
│   ├── music/                # FLAC/MP3 music files
│   └── photos/               # Immich mobile uploads and originals
└── backups/                  # Automated SQL and configuration tarballs
```
