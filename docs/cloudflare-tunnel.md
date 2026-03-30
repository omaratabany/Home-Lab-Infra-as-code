# Cloudflare Tunnel — Route Configuration

This documents the Zero Trust ingress routing for this homelab.

## Why Cloudflare Tunnel?

The WAN connection is behind **CGNAT** — there is no public IPv4 address available for port forwarding. Cloudflare Tunnel establishes an **outbound-only** encrypted connection from `cloudflared` on the host to Cloudflare's edge, eliminating the need for any open inbound ports.

```
No open ports on router ✓
No dynamic DNS required ✓
Free TLS via Cloudflare ✓
Zero Trust access policies available ✓
Works through any NAT depth ✓
```

---

## How routing works

The tunnel daemon runs on the **host network**. This means it can reach any container port that is mapped to the host via `-p HOST:CONTAINER`.

```
cloudflared (host network)
  │
  ├── plex.domain.com  ──►  localhost:32400  (Plex, host network — direct)
  ├── jellyfin.domain.com  ──►  localhost:8096
  ├── sonarr.domain.com    ──►  localhost:8989
  ├── radarr.domain.com    ──►  localhost:7878
  ├── overseerr.domain.com ──►  localhost:5055
  ├── jellyseerr.domain.com ──► localhost:5056
  ├── n8n.domain.com       ──►  localhost:5678
  ├── affine.domain.com    ──►  localhost:3010
  ├── nocodb.domain.com    ──►  localhost:8085
  └── mail.domain.com      ──►  localhost:25/587 (SMTP passthrough)
```

---

## Configuring routes in Zero Trust dashboard

Routes are **not** configured in `docker-compose.yml` — they live in the Cloudflare Zero Trust dashboard:

1. Go to [one.dash.cloudflare.com](https://one.dash.cloudflare.com)
2. **Networks → Tunnels → your tunnel → Configure → Public Hostnames**
3. Add a hostname for each service:

| Subdomain | Domain | Service | Path |
|---|---|---|---|
| plex | yourdomain.com | `http://localhost:32400` | — |
| jellyfin | yourdomain.com | `http://localhost:8096` | — |
| overseerr | yourdomain.com | `http://localhost:5055` | — |
| jellyseerr | yourdomain.com | `http://localhost:5056` | — |
| n8n | yourdomain.com | `http://localhost:5678` | — |
| affine | yourdomain.com | `http://localhost:3010` | — |
| nocodb | yourdomain.com | `http://localhost:8085` | — |

---

## Access policies (recommended)

For sensitive services (n8n, file managers, mail admin), add a Zero Trust access policy:

1. **Access → Applications → Add an application → Self-hosted**
2. Set the domain to match your tunnel hostname
3. Policy: **Require email OTP** or **Allow specific emails**

Services like Plex have their own auth — tunnel policy is optional but adds a layer.

---

## Metrics endpoint

`cloudflared` exposes a Prometheus metrics endpoint internally:

```
http://localhost:46495/metrics
```

Scrape this with your Prometheus instance (Grafana stack) for tunnel health monitoring.

---

## Token rotation procedure

If your tunnel token is compromised:

```bash
# 1. In Cloudflare dashboard: Networks → Tunnels → your tunnel → ... → Rotate token
# 2. Update your local .env:
nano docker-compose/networking/.env
# Set: CF_TUNNEL_TOKEN=<new_token>

# 3. Restart cloudflared:
make restart STACK=networking
# or:
docker restart Unraid-Cloudflared-Tunnel
```
