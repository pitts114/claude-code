.PHONY: start-agent stop-agent shell-agent shell-root-agent logs-agent list-agents cleanup cleanup-volumes cleanup-all build docker-build docker-push help

# Include docker-related targets
include docker.mk

# Default agent ID if not provided
ID ?= 1

# Calculate ports based on agent ID
EXTERNAL_PORT = $(shell echo $$((3000 + 10 * $(ID))))
POSTGRES_PORT = $(shell echo $$((5432 + 10 * $(ID))))
REDIS_PORT = $(shell echo $$((6379 + 10 * $(ID))))
INSTANCE_NAME = claude-code-agent-$(ID)
VOLUME_PREFIX = claude-code-agent-$(ID)
ENV_FILE = .env.$(ID)

# Default target
help:
	@echo "Claude Code Multi-Agent Container Management"
	@echo ""
	@echo "Usage:"
	@echo "  make start-agent ID=<agent_id>  - Start agent container (default ID=1)"
	@echo "  make stop-agent ID=<agent_id>   - Stop agent container"
	@echo "  make shell-agent ID=<agent_id>  - Open bash shell in agent container"
	@echo "  make logs-agent ID=<agent_id>   - View logs for agent container"
	@echo "  make list-agents                - List all running agent containers"
	@echo "  make cleanup                    - Stop and remove all agent containers"
	@echo "  make cleanup-volumes            - Remove all agent directories"
	@echo "  make cleanup-all                - Stop containers and remove volumes"
	@echo "  make build                      - Build the base Docker image"
	@echo ""
	@echo "Environment files:"
	@echo "  Each agent uses .env.<ID> (e.g., .env.1, .env.2)"
	@echo "  If .env.<ID> doesn't exist, it's created from .env"
	@echo ""
	@echo "Port mappings per agent:"
	@echo "  HTTP: 3000 + 10 * ID  |  PostgreSQL: 5432 + 10 * ID  |  Redis: 6379 + 10 * ID"
	@echo ""
	@echo "Examples:"
	@echo "  make start-agent ID=1          - Agent 1: HTTP 3010, PostgreSQL 5442, Redis 6389"
	@echo "  make start-agent ID=5          - Agent 5: HTTP 3050, PostgreSQL 5482, Redis 6429"
	@echo "  make shell-agent ID=1          - Opens bash in agent 1"

start-agent:
	@echo "Creating directories for Claude Code Agent $(ID)..."
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/workspace
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/bashhistory
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/config
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/docker-data
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "Warning: $(ENV_FILE) not found, creating from .env template..."; \
		cp .env $(ENV_FILE) 2>/dev/null || touch $(ENV_FILE); \
	fi
	@echo "Starting Claude Code Agent $(ID) on port $(EXTERNAL_PORT) with $(ENV_FILE)..."
	@EXTERNAL_PORT=$(EXTERNAL_PORT) \
	 POSTGRES_PORT=$(POSTGRES_PORT) \
	 REDIS_PORT=$(REDIS_PORT) \
	 INSTANCE_NAME=$(INSTANCE_NAME) \
	 VOLUME_PREFIX=$(VOLUME_PREFIX) \
	 docker compose --env-file $(ENV_FILE) -p "claude-agent-$(ID)" up -d
	@echo "Waiting for container to be ready..."
	@until docker exec $(INSTANCE_NAME) echo "ready" 2>/dev/null; do sleep 1; done
	@echo "Initializing firewall for Agent $(ID)..."
	@docker exec $(INSTANCE_NAME) sudo /usr/local/bin/init-firewall.sh
	@echo "Agent $(ID) started successfully!"
	@echo "  - Container: $(INSTANCE_NAME)"
	@echo "  - HTTP port: $(EXTERNAL_PORT):3000"
	@echo "  - PostgreSQL port: $(POSTGRES_PORT):5432"
	@echo "  - Redis port: $(REDIS_PORT):6379"
	@echo "  - Directories: ./volumes/$(VOLUME_PREFIX)/{workspace,bashhistory,config,claude-auth,docker-data}"
	@echo "  - Connect with: make shell-agent ID=$(ID)"

stop-agent:
	@echo "Stopping Claude Code Agent $(ID)..."
	@EXTERNAL_PORT=$(EXTERNAL_PORT) \
	 POSTGRES_PORT=$(POSTGRES_PORT) \
	 REDIS_PORT=$(REDIS_PORT) \
	 INSTANCE_NAME=$(INSTANCE_NAME) \
	 VOLUME_PREFIX=$(VOLUME_PREFIX) \
	 docker compose --env-file $(ENV_FILE) -p "claude-agent-$(ID)" down
	@echo "Agent $(ID) stopped successfully!"

shell-agent:
	@echo "Opening shell in Claude Code Agent $(ID)..."
	@docker exec -it $(INSTANCE_NAME) bash

shell-root-agent:
	@echo "Opening shell in Claude Code Agent $(ID)..."
	@docker exec -it -u root $(INSTANCE_NAME) bash

logs-agent:
	@echo "Showing logs for Claude Code Agent $(ID)..."
	@docker logs -f $(INSTANCE_NAME)

list-agents:
	@echo "Running Claude Code Agent containers:"
	@docker ps --filter "name=claude-code-agent" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

cleanup:
	@echo "Stopping and removing all Claude Code Agent containers..."
	@docker ps -q --filter "name=claude-code-agent" | xargs -r docker stop
	@docker ps -aq --filter "name=claude-code-agent" | xargs -r docker rm
	@echo "Cleanup completed!"

cleanup-volumes:
	@echo "Removing all Claude Code Agent directories..."
	@rm -rf ./volumes/claude-code-agent-*
	@echo "Directory cleanup completed!"

cleanup-all: cleanup cleanup-volumes
	@echo "Full cleanup (containers and directories) completed!"

