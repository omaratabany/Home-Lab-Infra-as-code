# Architecture Deep Dive

## Host Hardware

| Component | Spec |
|---|---|
| Machine | Minisforum MS-01 |
| CPU | Intel Core i9-12900H (16C/24T, P+E hybrid) |
| RAM | 64GB DDR5 |
| Boot | Unraid 7.x on USB |
| NVMe | 2× internal (OS cache + appdata) |
| DAS | TerraMaster (62TB raw, Unraid parity array) |
| NIC | 2.5GbE + 10GbE SFP+ |

## Network Design

### Physical layer
- **Router/AP**: UniFi (UDM or equivalent)
- **Switching**: UniFi managed switches
- **WAN**: ISP (UAE) — **CGNAT** (no inbound port forwarding available)

### CGNAT workaround — Cloudflare Tunnel
Because the WAN connection is behind CGNAT, there is no public IPv4 to forward ports to. The entire remote access layer is handled by **Cloudflare Tunnel** (`cloudflared`):

```
Remote Client
     │
     ▼
Cloudflare Edge (anycast)
     │  encrypted tunnel (QUIC/HTTP2)
     ▼
cloudflared daemon (host network on Unraid)
     │  localhost TCP
     ▼
Container port (e.g. :32400 for Plex)
```

Benefits:
- Zero open inbound ports
- Free TLS certificates via Cloudflare
- Zero Trust access policies (IP allowlist, email OTP, etc.)
- Works through any NAT/CGNAT

### Docker networking strategy

| Pattern | When used | Example |
|---|---|---|
| `network_mode: host` | Service needs LAN multicast or must bind to host IP | Plex (DLNA/GDM), cloudflared |
| Default `bridge` (172.17.x.x) | Most services — port-mapped to host | *arr stack, n8n, bazarr |
| Custom isolated bridge | Multi-container stacks sharing a DB | affine_default, nocobase_net |
| `macvlan` (br0) | Service needs a real LAN IP (legacy/DLNA devices) | Available, used selectively |

## Permission Model

All containers run with:
- `PUID=99` → Unraid's `nobody` user
- `PGID=100` → Unraid's `users` group

This ensures containers can read/write to Unraid shares without running as root, and that file ownership is consistent across the array.

## Transcoding Pipeline

```
Media file → Tdarr → hevc_qsv (Intel QSV on i9-12900H iGPU)
                  └─► Output replaces or sits alongside original
```

- Hardware device: `/dev/dri` passed into Tdarr container
- Format target: HEVC/H.265 (reduces storage ~40–60% vs H.264)
- Tdarr also handles audio stream normalization and subtitle extraction

## Subtitle Automation

```
Bazarr
  ├── Providers: Subscene, OpenSubtitles, Addic7ed
  ├── Languages: Arabic (priority), English, Spanish
  └── Triggers: new file detected via Sonarr/Radarr webhook
```

## Backup Strategy

| What | How | Where |
|---|---|---|
| Unraid config (USB) | UnraidConfigGuardian (weekly cron) | `/boot` snapshot |
| Container appdata | Unraid VM/backup plugin | Secondary array disk |
| Compose + IaC | **This repo** (GitHub) | Public, secrets stripped |
| Media | Parity array (Unraid) | TerraMaster DAS |
