# =============================================================================
# Homelab IaC — Makefile
# Usage: make <target> STACK=<stack-name>
# =============================================================================

STACKS := media-stack productivity automation networking mail utilities
COMPOSE_DIR := docker-compose

.PHONY: help up down restart logs pull ps validate

help:
	@echo ""
	@echo "  Homelab IaC — Stack Manager"
	@echo ""
	@echo "  Usage: make <target> [STACK=<name>]"
	@echo ""
	@echo "  Targets:"
	@echo "    up       STACK=x   Start a stack (detached)"
	@echo "    down     STACK=x   Stop and remove containers"
	@echo "    restart  STACK=x   Restart a stack"
	@echo "    logs     STACK=x   Tail logs (Ctrl+C to exit)"
	@echo "    pull     STACK=x   Pull latest images"
	@echo "    ps                 Status of all containers across all stacks"
	@echo "    validate           Validate all compose files (dry-run)"
	@echo "    up-all             Start all stacks"
	@echo "    down-all           Stop all stacks"
	@echo ""
	@echo "  Stacks: $(STACKS)"
	@echo ""

up:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<name>"; exit 1)
	@[ -f "$(COMPOSE_DIR)/$(STACK)/.env" ] || (echo "WARNING: No .env found — copy from .env.example first"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml --env-file $(COMPOSE_DIR)/$(STACK)/.env up -d

down:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<name>"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml down

restart:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<name>"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml restart

logs:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<name>"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml logs -f --tail=100

pull:
	@[ -n "$(STACK)" ] || (echo "ERROR: Specify STACK=<name>"; exit 1)
	docker compose -f $(COMPOSE_DIR)/$(STACK)/docker-compose.yml pull

ps:
	@for stack in $(STACKS); do \
		echo "\n=== $$stack ==="; \
		docker compose -f $(COMPOSE_DIR)/$$stack/docker-compose.yml ps 2>/dev/null || true; \
	done

validate:
	@echo "Validating all compose files..."
	@for stack in $(STACKS); do \
		echo -n "  $$stack ... "; \
		docker compose -f $(COMPOSE_DIR)/$$stack/docker-compose.yml config -q && echo "OK" || echo "FAILED"; \
	done

up-all:
	@for stack in $(STACKS); do \
		if [ -f "$(COMPOSE_DIR)/$$stack/.env" ]; then \
			echo "Starting $$stack..."; \
			docker compose -f $(COMPOSE_DIR)/$$stack/docker-compose.yml --env-file $(COMPOSE_DIR)/$$stack/.env up -d; \
		else \
			echo "SKIP $$stack — no .env file"; \
		fi \
	done

down-all:
	@for stack in $(STACKS); do \
		echo "Stopping $$stack..."; \
		docker compose -f $(COMPOSE_DIR)/$$stack/docker-compose.yml down 2>/dev/null || true; \
	done
