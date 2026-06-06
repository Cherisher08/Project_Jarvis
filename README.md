# Home Lab System - Ubuntu Server Foundation Setup (Phase 1)

This repository contains the configuration files and automation scripts to deploy a private, self-hosted home lab system running on **Ubuntu Server 22.04 LTS (Headless)**.

---

## Repository Structure

```
├── scripts/
│   └── setup.sh             # Server post-install setup script (Cockpit, Docker, Tailscale)
├── config/
│   ├── compose/
│   │   └── foundation.yml   # Docker Compose services for Portainer CE & Nginx Proxy Manager
│   ├── docker-compose.yml   # Master Compose file using 'include' directives
│   └── .env.example         # Template environment variables file for all secrets
└── README.md                # This setup guide
```

---

## Step-by-Step Deployment Instructions

### Step 1: Prepare your Ubuntu Server
1. Install a fresh copy of **Ubuntu Server 22.04 LTS** (headless, without a GUI) from a bootable USB drive on your Mini PC.
2. During installation, set up a standard user account (e.g., username: `vigner`) and note the local IP address assigned to the server.
3. Connect the server to your home network via an Ethernet cable for maximum stability.

---

### Step 2: Run the Server Setup Script
The `setup.sh` script automates the installation of system prerequisites, Docker Engine, Cockpit, and Tailscale VPN. It also establishes the directory structure in `/opt/homelab/`.

1. Copy the `scripts/setup.sh` file from this repository to your Ubuntu Server. You can use SSH, SCP, or copy-paste it directly.
2. Log into your Ubuntu Server terminal and navigate to the directory where you placed `setup.sh`.
3. Make the script executable and run it as root:
   ```bash
   chmod +x setup.sh
   sudo ./setup.sh
   ```
4. Follow the prompt instructions. Once completed, **log out and log back in** (or run `newgrp docker`) to apply the Docker group membership changes to your user.

---

### Step 3: Set up Secure Remote Access (Tailscale)
Tailscale enables secure remote access to your server from anywhere in the world without opening ports on your home router.

1. In the server terminal, start the Tailscale connection process:
   ```bash
   sudo tailscale up
   ```
2. Copy the URL printed in the terminal and open it in a browser on your phone or computer.
3. Authenticate with your Tailscale account to connect the Mini PC to your personal VPN mesh.
4. Install the Tailscale app on your daily devices (phone, laptop, tablet). Once enabled, you can access your home server from anywhere.

---

### Step 4: Deploy the Configuration Files
1. Copy the entire `config/` directory from this repository into `/opt/homelab/config/` on your Ubuntu Server.
2. Navigate to the configuration directory:
   ```bash
   cd /opt/homelab/config/
   ```
3. Duplicate the environment template to create your `.env` file:
   ```bash
   cp .env.example .env
   ```
4. Secure the `.env` file permissions so only your user can read it:
   ```bash
   chmod 600 .env
   ```
5. Edit the `.env` file to customize your variables (like timezone, passwords, and IP addresses):
   ```bash
   nano .env
   ```
   *(Press `Ctrl+O` then `Enter` to save, and `Ctrl+X` to exit nano editor)*

---

### Step 5: Start the Foundation Services
1. Run the following command from `/opt/homelab/config/` to spin up the foundation containers (Portainer CE and Nginx Proxy Manager):
   ```bash
   docker compose up -d
   ```
2. Check the container status:
   ```bash
   docker compose ps
   ```
   Both `hl_portainer` and `hl_nginx_proxy_manager` should show `Up (healthy)`.

---

## Service Verification & Access Checklist

Once deployed, verify that you can access all server management control panels:

| Dashboard | Address | Description / Usage |
| :--- | :--- | :--- |
| **🖥️ Cockpit** | `http://<SERVER_IP>:9090` | Web terminal, CPU/RAM monitoring, and OS updates. Log in with your standard Ubuntu username and password. |
| **🐳 Portainer CE** | `http://<SERVER_IP>:9000` | Graphic UI for container logs, metrics, container restarts, and stack status updates. |
| **🌐 Nginx Proxy Manager** | `http://<SERVER_IP>:81` | Web admin console to manage reverse proxies and SSL certificates. Default login: `admin@example.com` / `changeme` (please update immediately upon login!). |

---

## Next Steps
In **Phase 2: Network**, we will deploy **Pi-hole + Unbound** for network-wide ad blocking and internal DNS resolution, allowing you to access these services using clean names (like `http://portainer.home` and `http://nginx.home`) instead of typing IP addresses and port numbers.
