#!/bin/bash

# Container entrypoint script
# Handles runtime GitHub authentication setup before executing the main command

set -e

# Function to setup GitHub authentication
setup_github_auth() {
    echo "🔧 Setting up GitHub authentication..." >&2
    
    # Get GitHub username via API
    GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user 2>/dev/null | jq -r '.login' 2>/dev/null)
    
    # Validate username
    if [ -z "$GITHUB_USER" ] || [ "$GITHUB_USER" = "null" ]; then
        echo "⚠️  Warning: Could not retrieve GitHub username. Check GITHUB_TOKEN validity." >&2
        return 1
    fi
    
    # Create git credentials file
    echo "https://$GITHUB_USER:$GITHUB_TOKEN@github.com" > ~/.git-credentials
    chmod 600 ~/.git-credentials
    
    # Setup GitHub CLI authentication
    echo "$GITHUB_TOKEN" | gh auth login --with-token >/dev/null 2>&1
    
    echo "✅ GitHub authentication configured for user: $GITHUB_USER" >&2
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