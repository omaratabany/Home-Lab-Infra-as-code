# Deploying on Unraid

This guide covers deploying this IaC repo specifically on Unraid 6.12+ / 7.x.

---

## Recommended: Deploy via Unraid Terminal

Unraid doesn't have `make` by default. Install it first, or use the compose commands directly.

### Option A — Install make via Nerd Tools plugin

1. Install **Nerd Tools** from Community Apps
2. Enable `make` in Nerd Tools
3. Then: `make up STACK=media-stack`

### Option B — Direct compose commands (no make needed)

```bash
cd /path/to/homelab-iac
docker compose -f docker-compose/media-stack/docker-compose.yml \
               --env-file docker-compose/media-stack/.env \
               up -d
```

---

## Clone the repo to a persistent location

Unraid's `/` is tmpfs and resets on reboot. Clone to your array:

```bash
mkdir -p /mnt/user/appdata/homelab-iac
cd /mnt/user/appdata/homelab-iac
git clone https://github.com/YOUR_USERNAME/homelab-iac.git .
```

Or to the USB (persists, but USB is slow — fine for config files):
```bash
mkdir -p /boot/config/homelab-iac
cd /boot/config/homelab-iac
git clone https://github.com/YOUR_USERNAME/homelab-iac.git .
```

---

## Path conventions used in this repo

All `.env.example` files use these standard Unraid paths:

| Variable | Default Unraid path |
|---|---|
| `APPDATA` | `/mnt/user/appdata` |
| `MEDIA_PATH` | `/mnt/user/media` |
| `DOWNLOADS_PATH` | `/mnt/user/downloads` |

Adjust if your shares are named differently.

---

## PUID/PGID on Unraid

Unraid's default permission model:
- `PUID=99` → `nobody` (Unraid's unprivileged user)
- `PGID=100` → `users` (standard group with share access)

All containers in this repo use these defaults. If you've changed your share permissions to a named user, update accordingly.

---

## Using Unraid's GPU passthrough with Tdarr + Jellyfin

Both Tdarr and Jellyfin are configured to use `/dev/dri` for Intel Quick Sync.

On Unraid, make sure:
1. **Intel GPU TOP** plugin is installed (optional but useful for monitoring)
2. The host has `i915` kernel module loaded:
   ```bash
   lsmod | grep i915
   ```
3. `/dev/dri` exists on the host:
   ```bash
   ls /dev/dri
   # Expected: card0  renderD128
   ```

---

## Keeping the repo in sync with your running stack

When you change a container in the Unraid GUI, re-export and commit:

```bash
# On Unraid terminal:
for c in $(docker ps -a --format '{{.Names}}'); do
  docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}'
done > /mnt/user/appdata/homelab-iac/docs/current-env-snapshot.txt

cd /mnt/user/appdata/homelab-iac
git add docs/current-env-snapshot.txt
git commit -m "chore: sync env snapshot $(date +%Y-%m-%d)"
git push
```

---

## Auto-update images with Watchtower (optional)

Not included in this repo by default — Unraid's CA Auto Update handles this via the GUI. If you prefer CLI:

```bash
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --schedule "0 0 4 * * *" \
  --cleanup \
  --label-enable
```

Add `com.centurylinklabs.watchtower.enable=true` label to containers you want auto-updated.
