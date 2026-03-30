# 🏠 Homelab Infrastructure as Code

> Self-hosted media, productivity, automation, and networking stack running on **Unraid** (Minisforum MS-01), managed via Docker Compose. Built to demonstrate real-world DevOps practices: multi-stack service orchestration, network segmentation, secret management, and remote access via zero-trust tunneling.

---

## 📐 Architecture Overview

```
                          Internet
                              │
                    ┌─────────▼──────────┐
                    │  Cloudflare Tunnel  │  (Zero-trust, no open ports)
                    │  cloudflared        │
                    └─────────┬──────────┘
                              │ host network
              ┌───────────────▼───────────────┐
              │        Unraid Host             │
              │    Minisforum MS-01            │
              │  i9-12900H · 64GB · NVMe       │
              │  TerraMaster DAS (62TB)        │
              └──┬────────────┬───────────────┘
                 │            │
         ┌───────▼──┐  ┌──────▼────────────────┐
         │  br0      │  │   bridge 172.17.0.0/16 │
         │ macvlan   │  │                        │
         │ 192.168.x │  │  Media · Automation    │
         └───────────┘  │  Productivity · Mail   │
                        └───────────────────────┘
```

---

## 🗂️ Stack Layout

| Stack | Services | Network |
|---|---|---|
| [Media](#media-stack) | Plex, Jellyfin, Sonarr, Radarr, Bazarr, Prowlarr, Jackett, SABnzbd, qBittorrent, Tdarr, Tautulli, Overseerr, Jellyseerr, FlareSolverr | `bridge` |
| [Productivity](#productivity-stack) | AFFiNE (+ Postgres + Redis), NocoDB, NocoBase | isolated bridge networks |
| [Automation](#automation-stack) | n8n | `bridge` |
| [Networking](#networking-stack) | Cloudflare Tunnel, Unraid Config Guardian | `host` |
| [Mail](#mail-stack) | Docker Mailserver (Postfix/Dovecot) | `bridge` |
| [Utilities](#utilities) | Krusader, JDownloader2, Video Duplicate Finder | `bridge` |

---

## 🌐 Network Topology

| Network | Driver | Subnet | Purpose |
|---|---|---|---|
| `bridge` | bridge | `172.17.0.0/16` | Default inter-container, most services |
| `host` | host | — | Plex (DLNA/GDM), Cloudflared tunnel |
| `br0` | macvlan | `192.168.0.0/24` | Host-accessible IPs for select containers |
| `affine_default` | bridge | `172.20.0.0/16` | AFFiNE internal stack |
| `nocobase_net` | bridge | `172.24.0.0/16` | NocoBase + Postgres isolation |

> **Why macvlan (`br0`)?** Plex requires host-level multicast for DLNA and GDM discovery. Macvlan gives it a real LAN IP without exposing the host stack.

> **Why host network for Cloudflared?** Allows the tunnel daemon to reach all bridge-networked containers by their host-mapped ports without extra routing rules.

---

## 📦 Stacks

### Media Stack
`docker-compose/media-stack/`

Full *arr + Plex/Jellyfin dual-server setup with shared download clients.

**Service map:**
```
Prowlarr/Jackett ──► Sonarr ──► SABnzbd / qBittorrent
                 └──► Radarr ──►
                           │
                    Plex ◄─┤─► Jellyfin
                           │
               Tautulli ◄──┘    Bazarr (subtitles)
                                Tdarr  (transcoding QSV)
```

### Productivity Stack
`docker-compose/productivity/`

- **AFFiNE** — self-hosted Notion/Miro alternative (Postgres 16 + Redis)
- **NocoDB** — Airtable alternative
- **NocoBase** — low-code app builder (Postgres 16)

### Automation Stack
`docker-compose/automation/`

- **n8n** — workflow automation, webhook-driven, 400+ integrations

### Networking Stack
`docker-compose/networking/`

- **Cloudflare Tunnel** — zero-trust remote access, no port forwarding, CGNAT-safe
- **Unraid Config Guardian** — scheduled config backup with optional Tailscale delivery

### Mail Stack
`docker-compose/mail/`

- **Docker Mailserver** — full Postfix/Dovecot stack with SpamAssassin, ClamAV, Postgrey, ManageSieve

---

## 🚀 Getting Started

### Prerequisites
- Unraid 7.x (or any Docker host with `docker compose` v2)
- Cloudflare account + tunnel token
- Domain with Cloudflare DNS

### 1. Clone & configure

```bash
git clone https://github.com/YOUR_USERNAME/homelab-iac.git
cd homelab-iac
```

### 2. Set environment variables

Each stack has a `.env.example`. Copy and fill:

```bash
for stack in docker-compose/*/; do
  cp "$stack/.env.example" "$stack/.env"
done
# Then edit each .env with your actual values
```

### 3. Deploy a stack

```bash
# Media stack
make up STACK=media-stack

# Or directly
cd docker-compose/media-stack && docker compose up -d
```

---

## 🔐 Secret Management

- **Never commit `.env` files** — `.gitignore` covers them
- All secrets are injected via environment variables at runtime
- Cloudflare Tunnel token is passed as `CF_TUNNEL_TOKEN` — never hardcoded
- Database passwords use long random strings (≥32 chars recommended)

Generate a strong password:
```bash
openssl rand -base64 32
```

---

## 🛠️ Makefile Commands

```bash
make up    STACK=media-stack     # Start a stack
make down  STACK=media-stack     # Stop a stack
make logs  STACK=media-stack     # Tail logs
make pull  STACK=media-stack     # Pull latest images
make ps                          # Status of all stacks
```

---

## 📁 Repository Structure

```
homelab-iac/
├── docker-compose/
│   ├── media-stack/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   ├── productivity/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   ├── automation/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   ├── networking/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   ├── mail/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   └── utilities/
│       ├── docker-compose.yml
│       └── .env.example
├── docs/
│   ├── architecture.md
│   └── services.md
├── .github/
│   └── workflows/
│       └── lint.yml
├── Makefile
├── .gitignore
└── README.md
```

---

## 📄 License

MIT — feel free to use as a reference for your own homelab IaC setup.
