.PHONY: start-agent stop-agent shell-agent logs-agent list-agents cleanup help

# Default agent ID if not provided
ID ?= 1

# Calculate port: 3000 + 10 * ID
EXTERNAL_PORT = $(shell echo $$((3000 + 10 * $(ID))))
INSTANCE_NAME = claude-code-agent-$(ID)
VOLUME_PREFIX = claude-code-agent-$(ID)

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
	@echo "Examples:"
	@echo "  make start-agent ID=1          - Starts agent 1 on port 3010"
	@echo "  make start-agent ID=5          - Starts agent 5 on port 3050"
	@echo "  make shell-agent ID=1          - Opens bash in agent 1"

start-agent:
	@echo "Creating directories for Claude Code Agent $(ID)..."
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/workspace
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/bashhistory
	@mkdir -p ./volumes/$(VOLUME_PREFIX)/config
	@echo "Starting Claude Code Agent $(ID) on port $(EXTERNAL_PORT)..."
	@EXTERNAL_PORT=$(EXTERNAL_PORT) \
	 INSTANCE_NAME=$(INSTANCE_NAME) \
	 VOLUME_PREFIX=$(VOLUME_PREFIX) \
	 docker compose up -d
	@echo "Waiting for container to be ready..."
	@until docker exec $(INSTANCE_NAME) echo "ready" 2>/dev/null; do sleep 1; done
	@echo "Initializing firewall for Agent $(ID)..."
	@docker exec $(INSTANCE_NAME) sudo /usr/local/bin/init-firewall.sh
	@echo "Agent $(ID) started successfully!"
	@echo "  - Container: $(INSTANCE_NAME)"
	@echo "  - Port mapping: $(EXTERNAL_PORT):3000"
	@echo "  - Directories: ./volumes/$(VOLUME_PREFIX)/{workspace,bashhistory,config}"
	@echo "  - Connect with: make shell-agent ID=$(ID)"

stop-agent:
	@echo "Stopping Claude Code Agent $(ID)..."
	@EXTERNAL_PORT=$(EXTERNAL_PORT) \
	 INSTANCE_NAME=$(INSTANCE_NAME) \
	 VOLUME_PREFIX=$(VOLUME_PREFIX) \
	 docker compose down
	@echo "Agent $(ID) stopped successfully!"

shell-agent:
	@echo "Opening shell in Claude Code Agent $(ID)..."
	@docker exec -it $(INSTANCE_NAME) bash

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

# Build the base image
build:
	@echo "Building Claude Code base image..."
	@docker compose build
	@echo "Base image built successfully!"
