# =============================================================================
# Homelab IaC -- Makefile
# Usage: make <target> [STACK=<stack-name>] [TAGS=<ansible-tags>]
# =============================================================================

COMPOSE_STACKS := media-stack productivity automation networking mail utilities monitoring
COMPOSE_DIR    := docker-compose
ANSIBLE_DIR    := ansible
PLAYBOOK       := $(ANSIBLE_DIR)/playbooks/site.yml
INVENTORY      := $(ANSIBLE_DIR)/inventory/hosts.yml
STACK          ?=
TAGS           ?=

.PHONY: help \
        up down restart logs pull ps validate up-all down-all networks \
        provision deploy deploy-stack ansible-lint ansible-check \
        collections

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

help:
	@echo ""
	@echo "Homelab IaC -- Stack Manager"
	@echo ""
	@echo "Usage: make <target> [STACK=<n>] [TAGS=<ansible-tags>]"
	@echo ""
	@echo "Compose targets:"
	@echo "  networks              Create all external Docker networks (run once)"
	@echo "  up       STACK=x      Start a stack (detached)"
	@echo "  down     STACK=x      Stop and remove containers"
	@echo "  restart  STACK=x      Restart a stack"
	@echo "  logs     STACK=x      Tail logs (Ctrl+C to exit)"
	@echo "  pull     STACK=x      Pull latest images"
	@echo "  ps                    Status of all containers across all stacks"
	@echo "  validate              Validate all compose files (dry-run)"
	@echo "  up-all                Start all stacks"
	@echo "  down-all              Stop all stacks"
	@echo ""
	@echo "Ansible targets:"
	@echo "  provision             Run base host provisioning (unraid-base role)"
	@echo "  deploy                Deploy all stacks via Ansible"
	@echo "  deploy-stack TAGS=x   Deploy specific stack(s) -- e.g. TAGS=arr,monitoring"
	@echo "  ansible-check         Dry-run the full playbook (--check --diff)"
	@echo "  ansible-lint          Lint all playbooks and roles"
	@echo "  collections           Install required Ansible Galaxy collections"
	@echo ""
	@echo "Compose stacks: $(COMPOSE_STACKS)"
	@echo "Ansible tags:   base, networks, arr, media, network-stack, monitoring, stacks"
	@echo ""

# -----------------------------------------------------------------------------
# Docker network bootstrap (run once before first deploy)
# -----------------------------------------------------------------------------

networks:
	docker network create proxy_net      2>/dev/null || true
	docker network create media_net      2>/dev/null || true
	docker network create monitoring_net 2>/dev/null || true
	docker network create dns_net        2>/dev/null || true
	@echo "Networks ready"

# -----------------------------------------------------------------------------
# Compose targets
# -----------------------------------------------------------------------------

up:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<n>"; exit 1)
	@[ -f "$(COMPOSE_DIR)/$(STACK)/.env" ] || (echo "WARNING: No .env found -- copy from .env.example first"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml --env-file $(COMPOSE_DIR)/$(STACK)/.env up -d

down:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<n>"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml down

restart:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<n>"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml restart

logs:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<n>"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml logs -f --tail=100

pull:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<n>"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml pull

ps:
	@for stack in $(COMPOSE_STACKS); do \
		echo ""; \
		echo "=== $$stack ==="; \
		docker compose -f $(COMPOSE_DIR)/$$stack/docker-compose.yml ps 2>/dev/null || true; \
	done

validate:
	@echo "Validating all compose files..."
	@ERRORS=0; \
	for stack in $(COMPOSE_STACKS); do \
		printf "  %-20s" "$$stack"; \
		if docker compose -f $(COMPOSE_DIR)/$$stack/docker-compose.yml config --quiet 2>/dev/null; then \
			echo "OK"; \
		else \
			echo "FAILED"; ERRORS=$$((ERRORS+1)); \
		fi; \
	done; \
	exit $$ERRORS

up-all:
	@for stack in $(COMPOSE_STACKS); do \
		if [ -f "$(COMPOSE_DIR)/$$stack/.env" ]; then \
			echo "Starting $$stack..."; \
			docker compose -f $(COMPOSE_DIR)/$$stack/docker-compose.yml --env-file $(COMPOSE_DIR)/$$stack/.env up -d; \
		else \
			echo "SKIP $$stack -- no .env file"; \
		fi; \
	done

down-all:
	@for stack in $(COMPOSE_STACKS); do \
		echo "Stopping $$stack..."; \
		docker compose -f $(COMPOSE_DIR)/$$stack/docker-compose.yml down 2>/dev/null || true; \
	done

# -----------------------------------------------------------------------------
# Ansible targets
# -----------------------------------------------------------------------------

collections:
	ansible-galaxy collection install -r $(ANSIBLE_DIR)/requirements.yml

provision:
	ansible-playbook $(ANSIBLE_DIR)/playbooks/provision-unraid.yml \
		-i $(INVENTORY) \
		$(if $(VAULT_PASS),--vault-password-file $(VAULT_PASS),--ask-vault-pass)

deploy:
	ansible-playbook $(PLAYBOOK) \
		-i $(INVENTORY) \
		$(if $(VAULT_PASS),--vault-password-file $(VAULT_PASS),--ask-vault-pass)

deploy-stack:
	@[ -n "$(TAGS)" ] || (echo "ERROR: Specify TAGS=<ansible-tags>  e.g. TAGS=arr,monitoring"; exit 1)
	ansible-playbook $(PLAYBOOK) \
		-i $(INVENTORY) \
		--tags "$(TAGS)" \
		$(if $(VAULT_PASS),--vault-password-file $(VAULT_PASS),--ask-vault-pass)

ansible-check:
	ansible-playbook $(PLAYBOOK) \
		-i $(INVENTORY) \
		--check --diff \
		$(if $(VAULT_PASS),--vault-password-file $(VAULT_PASS),--ask-vault-pass)

ansible-lint:
	ansible-lint $(PLAYBOOK)
