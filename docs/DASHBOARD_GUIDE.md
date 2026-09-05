# Homepage Dashboard & Documentation Guide

The central dashboard serves as the single unified landing page for your entire homelab. Built with **Homepage**, it gives you live container status, system resource usage, and direct access to all 4 core apps without remembering individual port numbers.

---

## 1. Accessing Your Dashboard

- **Direct Port Access**: `http://<SERVER_IP>:3000`
- **Clean Subdomain Access**: `http://dashboard.home.lab` (configured via Nginx Proxy Manager + Pi-hole)
- **Over Tailscale**: Open `http://<TAILSCALE_IP>:3000` from any phone or computer authenticated on your Tailnet.

---

## 2. Dashboard Layout Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│  HomeLab Central                           [CPU: 12%] [RAM: 48%] [DATE] │
├────────────────────────────────────────────────────────────────────────┤
│  Personal Productivity                                                 │
│  ┌─────────────────────────────┐  ┌──────────────────────────────────┐ │
│  │ 📝 Memos                    │  │ 📚 Kavita                        │ │
│  │ Google Keep alternative     │  │ Ebooks, PDFs & Comics with OPDS  │ │
│  │ ● Online                    │  │ ● Online                         │ │
│  └─────────────────────────────┘  └──────────────────────────────────┘ │
│                                                                        │
│  Media & Memories                                                      │
│  ┌─────────────────────────────┐  ┌──────────────────────────────────┐ │
│  │ 📸 Immich (Lean)            │  │ 🎬 Jellyfin                      │ │
│  │ Mobile Auto-Backup          │  │ Movies, TV Shows & Music Stream  │ │
│  │ ● Online                    │  │ ● Online                         │ │
│  └─────────────────────────────┘  └──────────────────────────────────┘ │
│                                                                        │
│  Network & Administration                                              │
│  ┌─────────────────────────────┐  ┌──────────────────────────────────┐ │
│  │ 🛡️ Pi-hole                  │  │ 🌐 Nginx Proxy Manager           │ │
│  │ DNS Ad-blocker & Local DNS  │  │ Subdomain Routing & SSL Proxy    │ │
│  │ ● Online                    │  │ ● Online                         │ │
│  └─────────────────────────────┘  └──────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Live Health & Ping Integration

Every service card configured in `/opt/homelab/config/homepage/services.yaml` performs internal Docker network pings:
- **Memos**: Pings `http://hl_memos:5230`
- **Kavita**: Pings `http://hl_kavita:5000`
- **Immich**: Pings `http://hl_immich_server:2283/api/server-info/ping`
- **Jellyfin**: Pings `http://hl_jellyfin:8096/health`
- **Pi-hole**: Pings `http://hl_pihole:80`
- **Nginx Proxy Manager**: Pings `http://hl_nginx_proxy_manager:81`

If a container stops or encounters an issue, its indicator dot immediately changes from green to red.

---

## 4. Customizing Dashboard Shortcuts & Bookmarks

All dashboard configurations live in plain YAML files inside `/opt/homelab/config/homepage/`:

| File | Purpose |
| :--- | :--- |
| `settings.yaml` | Layout columns, color palette (e.g. `slate`, `zinc`), title, and themes |
| `services.yaml` | Service cards, icons, ping URLs, and descriptions |
| `widgets.yaml` | System hardware monitors (CPU, Memory, Disk utilization) |
| `bookmarks.yaml` | External reference links, guides, and administration consoles |

### Example: Adding an external bookmark to `bookmarks.yaml`
```yaml
- "Quick Tools":
    - "Fast Speedtest":
        - abbr: "SPD"
        - href: "https://fast.com"
        - description: "Check Internet Download Speed"
```
Changes take effect immediately upon saving the file—no container restart required!
