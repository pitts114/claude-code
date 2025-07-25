.PHONY: start-agent stop-agent shell-agent shell-root-agent logs-agent list-agents cleanup cleanup-volumes cleanup-all build docker-build docker-push help start-local-agent stop-local-agent shell-local-agent start-remote-agent stop-remote-agent shell-remote-agent

# Include docker-related targets
include docker.mk

# Default agent ID if not provided
ID ?= 1

# Optional remote Docker host (e.g., tcp://remote-host:2376)
REMOTE_HOST ?= $(shell grep REMOTE_HOST makefile.env 2>/dev/null | cut -d= -f2)

# Remote volumes path (where bind mounts are created on remote machine)
REMOTE_VOLUMES_PATH ?= /home/ubuntu/claude-volumes

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
	@echo "Local deployment commands (using bind mounts):"
	@echo "  make start-local-agent ID=<agent_id>  - Start local agent container"
	@echo "  make stop-local-agent ID=<agent_id>   - Stop local agent container"
	@echo "  make shell-local-agent ID=<agent_id>  - Open bash shell in local agent"
	@echo ""
	@echo "Remote deployment commands (using Docker volumes):"
	@echo "  make start-remote-agent ID=<agent_id> - Start remote agent container"
	@echo "  make stop-remote-agent ID=<agent_id>  - Stop remote agent container"
	@echo "  make shell-remote-agent ID=<agent_id> - Open bash shell in remote agent"
	@echo ""
	@echo "General commands:"
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
	@echo "  make start-local-agent ID=1    - Local Agent 1: HTTP 3010, PostgreSQL 5442, Redis 6389"
	@echo "  make start-remote-agent ID=5   - Remote Agent 5: HTTP 3050, PostgreSQL 5482, Redis 6429"
	@echo "  make shell-local-agent ID=1    - Opens bash in local agent 1"
	@echo "  make shell-remote-agent ID=1   - Opens bash in remote agent 1"

# =============================================================================
# BACKWARDS COMPATIBILITY ALIASES (default to local deployment)
# =============================================================================

start-agent: start-local-agent
	@echo "Note: 'start-agent' defaults to local deployment. Use 'start-remote-agent' for remote."

stop-agent: stop-local-agent
	@echo "Note: 'stop-agent' defaults to local deployment. Use 'stop-remote-agent' for remote."

shell-agent: shell-local-agent
	@echo "Note: 'shell-agent' defaults to local deployment. Use 'shell-remote-agent' for remote."

shell-root-agent:
	@echo "Opening root shell in Claude Code Agent $(ID) (LOCAL)..."
	@docker exec -it -u root $(INSTANCE_NAME) bash

logs-agent:
	@echo "Showing logs for Claude Code Agent $(ID)..."
	@$(if $(REMOTE_HOST),DOCKER_HOST=$(REMOTE_HOST)) docker logs -f $(INSTANCE_NAME)

list-agents:
	@echo "Running Claude Code Agent containers:"
	@$(if $(REMOTE_HOST),DOCKER_HOST=$(REMOTE_HOST)) docker ps --filter "name=claude-code-agent" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

cleanup:
	@echo "Stopping and removing all Claude Code Agent containers..."
	@$(if $(REMOTE_HOST),DOCKER_HOST=$(REMOTE_HOST)) docker ps -q --filter "name=claude-code-agent" | xargs -r $(if $(REMOTE_HOST),DOCKER_HOST=$(REMOTE_HOST)) docker stop
	@$(if $(REMOTE_HOST),DOCKER_HOST=$(REMOTE_HOST)) docker ps -aq --filter "name=claude-code-agent" | xargs -r $(if $(REMOTE_HOST),DOCKER_HOST=$(REMOTE_HOST)) docker rm
	@echo "Cleanup completed!"

cleanup-volumes:
	@echo "Removing all Claude Code Agent directories..."
	@rm -rf ./volumes/claude-code-agent-*
	@echo "Directory cleanup completed!"

cleanup-all: cleanup cleanup-volumes
	@echo "Full cleanup (containers and directories) completed!"

# =============================================================================
# LOCAL DEPLOYMENT COMMANDS (using docker-compose.local.yml)
# =============================================================================

start-local-agent:
	@echo "Creating directories for Claude Code Agent $(ID) (LOCAL)..."
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/workspace
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/bashhistory
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/config
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/docker-data
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "Warning: $(ENV_FILE) not found, creating from .env template..."; \
		cp .env $(ENV_FILE) 2>/dev/null || touch $(ENV_FILE); \
	fi
	@echo "Starting Claude Code Agent $(ID) on port $(EXTERNAL_PORT) with $(ENV_FILE) (LOCAL)..."
	@EXTERNAL_PORT=$(EXTERNAL_PORT) \
	 POSTGRES_PORT=$(POSTGRES_PORT) \
	 REDIS_PORT=$(REDIS_PORT) \
	 INSTANCE_NAME=$(INSTANCE_NAME) \
	 VOLUME_PREFIX=$(VOLUME_PREFIX) \
	 docker compose -f docker-compose.local.yml --env-file $(ENV_FILE) -p "claude-agent-$(ID)" up -d
	@echo "Waiting for container to be ready..."
	@until docker exec $(INSTANCE_NAME) echo "ready" 2>/dev/null; do sleep 1; done
	@echo "Initializing firewall for Agent $(ID)..."
	@docker exec $(INSTANCE_NAME) sudo /usr/local/bin/init-firewall.sh
	@echo "Local Agent $(ID) started successfully!"
	@echo "  - Container: $(INSTANCE_NAME)"
	@echo "  - HTTP port: $(EXTERNAL_PORT):3000"
	@echo "  - PostgreSQL port: $(POSTGRES_PORT):5432"
	@echo "  - Redis port: $(REDIS_PORT):6379"
	@echo "  - Directories: ./volumes/$(VOLUME_PREFIX)/{workspace,bashhistory,config,claude-auth,docker-data}"
	@echo "  - Connect with: make shell-local-agent ID=$(ID)"

stop-local-agent:
	@echo "Stopping Claude Code Agent $(ID) (LOCAL)..."
	@EXTERNAL_PORT=$(EXTERNAL_PORT) \
	 POSTGRES_PORT=$(POSTGRES_PORT) \
	 REDIS_PORT=$(REDIS_PORT) \
	 INSTANCE_NAME=$(INSTANCE_NAME) \
	 VOLUME_PREFIX=$(VOLUME_PREFIX) \
	 docker compose -f docker-compose.local.yml --env-file $(ENV_FILE) -p "claude-agent-$(ID)" down
	@echo "Local Agent $(ID) stopped successfully!"

shell-local-agent:
	@echo "Opening shell in Claude Code Agent $(ID) (LOCAL)..."
	@docker exec -it $(INSTANCE_NAME) bash

# =============================================================================
# REMOTE DEPLOYMENT COMMANDS (using docker-compose.remote.yml)
# =============================================================================

start-remote-agent:
	@echo "Starting Claude Code Agent $(ID) on remote host $(REMOTE_HOST)..."
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "Warning: $(ENV_FILE) not found, creating from .env template..."; \
		cp .env $(ENV_FILE) 2>/dev/null || touch $(ENV_FILE); \
	fi
	@echo "Creating directories on remote host..."
	@ssh $(shell echo $(REMOTE_HOST) | sed 's|ssh://||') \
		"mkdir -p $(REMOTE_VOLUMES_PATH)/$(VOLUME_PREFIX)/workspace && \
		 mkdir -p $(REMOTE_VOLUMES_PATH)/$(VOLUME_PREFIX)/bashhistory && \
		 mkdir -p $(REMOTE_VOLUMES_PATH)/$(VOLUME_PREFIX)/config && \
		 mkdir -p $(REMOTE_VOLUMES_PATH)/claude-auth"
	@echo "Starting Claude Code Agent $(ID) on port $(EXTERNAL_PORT) with $(ENV_FILE) (REMOTE)..."
	@EXTERNAL_PORT=$(EXTERNAL_PORT) \
	 POSTGRES_PORT=$(POSTGRES_PORT) \
	 REDIS_PORT=$(REDIS_PORT) \
	 INSTANCE_NAME=$(INSTANCE_NAME) \
	 VOLUME_PREFIX=$(VOLUME_PREFIX) \
	 REGISTRY=$(REGISTRY) \
	 REMOTE_VOLUMES_PATH=$(REMOTE_VOLUMES_PATH) \
	 DOCKER_HOST=$(REMOTE_HOST) \
	 docker compose -f docker-compose.remote.yml --env-file $(ENV_FILE) -p "claude-agent-$(ID)" up -d
	@echo "Waiting for container to be ready..."
	@until DOCKER_HOST=$(REMOTE_HOST) docker exec $(INSTANCE_NAME) echo "ready" 2>/dev/null; do sleep 1; done
	@echo "Initializing firewall for Agent $(ID)..."
	@DOCKER_HOST=$(REMOTE_HOST) docker exec $(INSTANCE_NAME) sudo /usr/local/bin/init-firewall.sh
	@echo "Remote Agent $(ID) started successfully!"
	@echo "  - Container: $(INSTANCE_NAME)"
	@echo "  - Remote host: $(REMOTE_HOST)"
	@echo "  - HTTP port: $(EXTERNAL_PORT):3000"
	@echo "  - PostgreSQL port: $(POSTGRES_PORT):5432"
	@echo "  - Redis port: $(REDIS_PORT):6379"
	@echo "  - Connect with: make shell-remote-agent ID=$(ID)"

stop-remote-agent:
	@echo "Stopping Claude Code Agent $(ID) on remote host $(REMOTE_HOST)..."
	@EXTERNAL_PORT=$(EXTERNAL_PORT) \
	 POSTGRES_PORT=$(POSTGRES_PORT) \
	 REDIS_PORT=$(REDIS_PORT) \
	 INSTANCE_NAME=$(INSTANCE_NAME) \
	 VOLUME_PREFIX=$(VOLUME_PREFIX) \
	 REGISTRY=$(REGISTRY) \
	 REMOTE_VOLUMES_PATH=$(REMOTE_VOLUMES_PATH) \
	 DOCKER_HOST=$(REMOTE_HOST) \
	 docker compose -f docker-compose.remote.yml --env-file $(ENV_FILE) -p "claude-agent-$(ID)" down
	@echo "Remote Agent $(ID) stopped successfully!"

shell-remote-agent:
	@echo "Opening shell in Claude Code Agent $(ID) on remote host $(REMOTE_HOST)..."
	@DOCKER_HOST=$(REMOTE_HOST) docker exec -it $(INSTANCE_NAME) bash

