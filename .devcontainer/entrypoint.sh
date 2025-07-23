#!/bin/bash

# Container entrypoint script
# Handles runtime GitHub authentication setup before executing the main command

set -e

# Function to setup rootless Docker daemon
setup_docker_daemon() {
    echo "🐳 Starting rootless Docker daemon..." >&2

    # Set environment for rootless Docker (must be done here for non-interactive entrypoint)
    export PATH=$HOME/bin:$PATH
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

    # Ensure runtime dir exists and has correct permissions
    mkdir -p "$XDG_RUNTIME_DIR"
    chown ubuntu:ubuntu "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"

    # Start rootless dockerd in the background with vfs storage, suppressing output
    dockerd-rootless.sh --experimental --storage-driver vfs >/dev/null 2>&1 &
    DOCKERD_PID=$!

    # Wait for Docker daemon to be ready
    local retries=0
    while ! docker info >/dev/null 2>&1; do
        if ! kill -0 $DOCKERD_PID 2>/dev/null; then
            echo "❌ Rootless Docker daemon failed to start" >&2
            return 1
        fi
        sleep 1
        if [ $retries -gt 10 ]; then
            echo "❌ Timeout waiting for Docker daemon" >&2
            return 1
        fi
        retries=$((retries+1))
    done

    echo "✅ Rootless Docker daemon started successfully" >&2
    return 0
}

# Function to setup Git configuration
setup_git_config() {
    echo "🔧 Setting up Git configuration..." >&2

    # Set git username and email if provided
    if [ -n "$GIT_USERNAME" ]; then
        git config --global user.name "$GIT_USERNAME"
        echo "✅ Git username set to: $GIT_USERNAME" >&2
    fi

    if [ -n "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
        echo "✅ Git email set to: $GIT_EMAIL" >&2
    fi

    return 0
}

# Function to setup GitHub authentication using official GitHub CLI method
setup_github_auth() {
    echo "🔧 Setting up GitHub authentication..." >&2

    # Authenticate GitHub CLI with token
    echo "$GITHUB_TOKEN" | gh auth login --with-token >/dev/null 2>&1

    # Configure git to use GitHub CLI authentication
    gh auth setup-git >/dev/null 2>&1

    echo "✅ GitHub authentication configured" >&2
    return 0
}


# Setup Docker daemon
setup_docker_daemon || echo "⚠️  Docker daemon setup failed, but continuing..." >&2

# Setup Git configuration
setup_git_config || echo "⚠️  Git configuration setup failed, but continuing..." >&2

# Setup GitHub authentication if token is available
if [ -n "$GITHUB_TOKEN" ]; then
    setup_github_auth || echo "⚠️  GitHub authentication setup failed, but continuing..." >&2
else
    echo "ℹ️  GITHUB_TOKEN not set, skipping GitHub authentication setup" >&2
fi


# Execute the main command
exec "$@"
