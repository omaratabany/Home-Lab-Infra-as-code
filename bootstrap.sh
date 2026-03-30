#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — First-time setup for homelab-iac on Unraid
# Run from the repo root: bash bootstrap.sh
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

STACKS=(media-stack productivity automation networking mail utilities)
COMPOSE_DIR="docker-compose"

log()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }

banner() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║     Homelab IaC — Bootstrap          ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
  echo ""
}

check_deps() {
  info "Checking dependencies..."
  local missing=0
  for cmd in docker git; do
    if command -v "$cmd" &>/dev/null; then
      log "$cmd found: $(command -v $cmd)"
    else
      err "$cmd not found — please install it first"
      missing=1
    fi
  done

  # docker compose v2
  if docker compose version &>/dev/null; then
    log "docker compose v2 found"
  else
    err "docker compose v2 not found (need Docker 20.10+)"
    missing=1
  fi

  [ $missing -eq 0 ] || { err "Missing dependencies. Aborting."; exit 1; }
}

setup_envs() {
  info "Setting up .env files from examples..."
  local created=0
  local skipped=0
  for stack in "${STACKS[@]}"; do
    local example="$COMPOSE_DIR/$stack/.env.example"
    local env="$COMPOSE_DIR/$stack/.env"
    if [ -f "$example" ]; then
      if [ -f "$env" ]; then
        warn "$stack/.env already exists — skipping (won't overwrite)"
        ((skipped++)) || true
      else
        cp "$example" "$env"
        log "Created $stack/.env"
        ((created++)) || true
      fi
    else
      warn "No .env.example found for $stack"
    fi
  done
  echo ""
  info "Created: $created  |  Skipped (already exist): $skipped"
}

check_secrets() {
  info "Scanning for accidentally hardcoded secrets..."
  local issues=0

  # Check for JWT-like tokens in compose files
  for stack in "${STACKS[@]}"; do
    local file="$COMPOSE_DIR/$stack/docker-compose.yml"
    if [ -f "$file" ]; then
      if grep -qE 'eyJ[a-zA-Z0-9+/]{20,}' "$file" 2>/dev/null; then
        err "Possible JWT/token hardcoded in $file — move to .env!"
        ((issues++)) || true
      fi
      if grep -qE '(password|secret|token)\s*[:=]\s*[a-zA-Z0-9]{16,}' "$file" 2>/dev/null; then
        warn "Possible hardcoded credential in $file — verify it uses \${VAR} syntax"
      fi
    fi
  done

  if [ $issues -eq 0 ]; then
    log "No obvious hardcoded secrets found in compose files"
  fi
}

validate_stacks() {
  info "Validating all compose files..."
  local failed=0
  for stack in "${STACKS[@]}"; do
    local compose="$COMPOSE_DIR/$stack/docker-compose.yml"
    local env="$COMPOSE_DIR/$stack/.env"
    if [ -f "$compose" ] && [ -f "$env" ]; then
      if docker compose -f "$compose" --env-file "$env" config -q 2>/dev/null; then
        log "$stack — valid"
      else
        err "$stack — INVALID compose file"
        ((failed++)) || true
      fi
    else
      warn "$stack — skipped (missing compose or .env)"
    fi
  done
  [ $failed -eq 0 ] || { err "$failed stack(s) failed validation. Fix before deploying."; }
}

print_next_steps() {
  echo ""
  echo -e "${BOLD}══════════════════════════════════════════════${NC}"
  echo -e "${BOLD}  Next Steps${NC}"
  echo -e "${BOLD}══════════════════════════════════════════════${NC}"
  echo ""
  echo "  1. Edit each stack's .env file with your real values:"
  for stack in "${STACKS[@]}"; do
    echo "       nano $COMPOSE_DIR/$stack/.env"
  done
  echo ""
  echo "  2. ⚠️  ROTATE your Cloudflare Tunnel token before pushing:"
  echo "       https://one.dash.cloudflare.com → Networks → Tunnels"
  echo "       Then set CF_TUNNEL_TOKEN in docker-compose/networking/.env"
  echo ""
  echo "  3. Deploy a stack:"
  echo "       make up STACK=networking"
  echo "       make up STACK=media-stack"
  echo ""
  echo "  4. Check status:"
  echo "       make ps"
  echo ""
  echo -e "  ${GREEN}Happy homelabbing.${NC}"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
banner
check_deps
setup_envs
check_secrets
validate_stacks
print_next_steps
