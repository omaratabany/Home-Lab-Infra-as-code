# Services Reference

A quick reference for every service in this stack: purpose, port, and access method.

## Media Stack

| Service | Port | Access | Purpose |
|---|---|---|---|
| Plex | host:32400 | LAN + Cloudflare Tunnel | Primary media server |
| Jellyfin | 8096 | LAN + Tunnel | Secondary/fallback media server |
| Sonarr | 8989 | LAN only | TV series automation |
| Radarr | 7878 | LAN only | Movie automation |
| Bazarr | 6767 | LAN only | Subtitle fetching (AR/EN/ES) |
| Prowlarr | 9696 | LAN only | Indexer management |
| Jackett | 9117 | LAN only | Fallback indexer proxy |
| FlareSolverr | 8191 | LAN only | Cloudflare JS challenge bypass |
| SABnzbd | 8080 | LAN only | Usenet download client |
| qBittorrent | 8082 | LAN only | Torrent download client |
| Tdarr | 8265 | LAN only | Media transcoding (QSV) |
| Tautulli | 8181 | LAN only | Plex analytics |
| Overseerr | 5055 | LAN + Tunnel | Plex request management |
| Jellyseerr | 5056 | LAN + Tunnel | Jellyfin request management |

## Productivity Stack

| Service | Port | Access | Purpose |
|---|---|---|---|
| AFFiNE | 3010 | LAN + Tunnel | Notion/Miro alternative |
| NocoDB | 8085 | LAN + Tunnel | Airtable alternative |
| NocoBase | 13000 | LAN + Tunnel | Low-code app builder |

## Automation Stack

| Service | Port | Access | Purpose |
|---|---|---|---|
| n8n | 5678 | LAN + Tunnel | Workflow automation |

## Networking Stack

| Service | Mode | Purpose |
|---|---|---|
| Cloudflared | host | Zero-trust ingress tunnel |
| Unraid Config Guardian | bridge | Weekly config backup |

## Mail Stack

| Service | Ports | Purpose |
|---|---|---|
| Docker Mailserver | 25, 143, 465, 587, 993, 4190 | Full SMTP/IMAP stack |

## Utilities

| Service | Port | Purpose |
|---|---|---|
| Krusader | 6080 | Dual-pane file manager (noVNC) |
| JDownloader2 | 5800 | HTTP/DDL download manager |
| Video Duplicate Finder | 5802 | Duplicate media scanner |
