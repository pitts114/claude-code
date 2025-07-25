# =============================================================================
# DOCKER BUILD CONFIGURATION
# =============================================================================
REGISTRY ?= $(shell grep REGISTRY makefile.env 2>/dev/null | cut -d= -f2)
IMAGE_NAME ?= claude-code-base
GIT_COMMIT := $(shell git rev-parse --short HEAD)
FULL_IMAGE_NAME := $(REGISTRY)$(IMAGE_NAME):$(GIT_COMMIT)
LATEST_IMAGE_NAME := $(REGISTRY)$(IMAGE_NAME):latest

# =============================================================================
# DOCKER BUILD TARGETS
# =============================================================================

# Build the base image
build:
	@echo "Building Claude Code base image..."
	@docker build -t claude-code-base:latest .devcontainer/
	@echo "Base image built successfully!"

docker-build:
	docker buildx build --platform linux/amd64 -t $(FULL_IMAGE_NAME) -t $(LATEST_IMAGE_NAME) --load .devcontainer/

docker-push:
	docker push $(FULL_IMAGE_NAME)
	docker push $(LATEST_IMAGE_NAME)
