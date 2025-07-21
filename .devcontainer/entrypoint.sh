#!/bin/bash

# Container entrypoint script
# Handles runtime GitHub authentication setup before executing the main command

set -e

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

# Setup GitHub authentication if token is available
if [ -n "$GITHUB_TOKEN" ]; then
    setup_github_auth || echo "⚠️  GitHub authentication setup failed, but continuing..." >&2
else
    echo "ℹ️  GITHUB_TOKEN not set, skipping GitHub authentication setup" >&2
fi

# Execute the main command
exec "$@"