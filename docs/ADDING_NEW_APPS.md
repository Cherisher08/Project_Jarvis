# Standard Operating Procedure (SOP): Adding New Containers

This guide provides an unambiguous, step-by-step procedure for both **human administrators** and **low-level AI models** to add any new container to the homelab system safely.

Follow these 4 rules at all times:
1. **Rule 1: Always enforce memory limits** (`deploy.resources.limits.memory`). Total container memory must not exceed the 4GB host RAM envelope.
2. **Rule 2: Never collide ports**. Check the port matrix in `docs/ARCHITECTURE.md` before picking a host port.
3. **Rule 3: Use the shared network** (`networks: - homelab_net`).
4. **Rule 4: Store persistent state** in `${DATA_ROOT}/<app_name>`.

---

## The 3-Step Uniform Process

```
┌─────────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────────┐
│         STEP 1          │     │         STEP 2          │     │         STEP 3          │
│ Create Compose Stack    │ ──► │ Register in Dashboard   │ ──► │ Route in Proxy & DNS   │
│ compose/07-<app_name>/  │     │ config/homepage/        │     │ Nginx Proxy Manager     │
└─────────────────────────┘     └─────────────────────────┘     └─────────────────────────┘
```

---

### Step 1: Create the Isolated Compose Stack

Create a new directory under `compose/` named with an incrementing number prefix, e.g., `compose/07-it-tools/docker-compose.yml`.

#### Template `docker-compose.yml`:
```yaml
services:
  <app_name>:
    image: <docker_image>:<tag>
    container_name: hl_<app_name>
    restart: unless-stopped
    ports:
      - "<HOST_PORT>:<CONTAINER_PORT>/tcp"
    environment:
      TZ: ${TZ:-Etc/UTC}
    volumes:
      - ${DATA_ROOT:-/opt/homelab/data}/<app_name>:/data
    networks:
      - homelab_net
    deploy:
      resources:
        limits:
          memory: 100M  # Set appropriately (e.g. 50M-200M)
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  homelab_net:
    name: homelab_net
    external: true
```

#### Launch the container:
```bash
docker compose --env-file /opt/homelab/.env -f /opt/homelab/compose/07-<app_name>/docker-compose.yml up -d
```

---

### Step 2: Register the Service on Homepage Dashboard

Open `/opt/homelab/config/homepage/services.yaml` and append the new card under the appropriate category:

```yaml
- "Personal Productivity":
    - "<App Display Name>":
        icon: <icon_name>.png
        href: "http://<app_name>.home.lab"
        description: "<Short 1-sentence description>"
        ping: "http://hl_<app_name>:<CONTAINER_PORT>"
        container: hl_<app_name>
```

The dashboard will refresh automatically and show the new service card with a live status indicator!

---

### Step 3: Configure DNS & Reverse Proxy Routing

1. **Add Local DNS Record in Pi-hole**:
   - Add entry to `/opt/homelab/config/pihole/custom.list`:
     ```
     <SERVER_IP> <app_name>.home.lab
     ```
   - Reload Pi-hole DNS:
     ```bash
     docker exec -it hl_pihole pihole restartdns reload
     ```

2. **Add Proxy Host in Nginx Proxy Manager**:
   - Navigate to `http://<SERVER_IP>:81`
   - Click **Proxy Hosts** ➔ **Add Proxy Host**
   - **Domain Names**: `<app_name>.home.lab`
   - **Scheme**: `http`
   - **Forward Hostname / IP**: `hl_<app_name>` (use container name directly over `homelab_net`!)
   - **Forward Port**: `<CONTAINER_PORT>`
   - Enable **Block Common Exploits** and **Websockets Support**
   - Click **Save**.

Your new service is now fully reachable at `http://<app_name>.home.lab` locally and over Tailscale!
