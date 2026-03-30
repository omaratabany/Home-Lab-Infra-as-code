#!/usr/bin/env bash
# =============================================================================
# git-init-push.sh — Initialize this repo and push to GitHub
# Run once from the repo root after cloning or creating fresh.
# Usage: bash git-init-push.sh <github-username> <repo-name>
# Example: bash git-init-push.sh omarXYZ homelab-iac
# =============================================================================

set -euo pipefail

GITHUB_USER="${1:-}"
REPO_NAME="${2:-homelab-iac}"

if [ -z "$GITHUB_USER" ]; then
  echo "Usage: bash git-init-push.sh <github-username> [repo-name]"
  exit 1
fi

echo ""
echo "==> Initializing git repo..."
git init
git checkout -b main

echo ""
echo "==> Staging all files..."
git add .

echo ""
echo "==> Verifying no .env files are staged..."
if git diff --cached --name-only | grep -E '(^|/)\.env$'; then
  echo "ERROR: .env file staged! Unstaging..."
  git restore --staged "**/.env"
fi

echo ""
echo "==> Commit..."
git commit -m "feat: initial homelab IaC — Unraid Docker stack

Stacks:
- media-stack: Plex, Jellyfin, *arr, Tdarr, Bazarr, SABnzbd, qBit
- productivity: AFFiNE, NocoDB, NocoBase
- automation: n8n
- networking: Cloudflare Tunnel, Config Guardian
- mail: Docker Mailserver (Postfix/Dovecot)
- utilities: Krusader, JDownloader2, Video Duplicate Finder

CI: compose validation + secret scan on push
Docs: architecture, services, cloudflare tunnel, unraid deployment"

echo ""
echo "==> Adding remote..."
git remote add origin "https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo ""
echo "============================================"
echo "  Repo ready. Push with:"
echo "    git push -u origin main"
echo ""
echo "  First, create the repo on GitHub:"
echo "    https://github.com/new"
echo "    Name: ${REPO_NAME}"
echo "    Visibility: Public"
echo "    Do NOT initialize with README (you have one)"
echo "============================================"
echo ""
