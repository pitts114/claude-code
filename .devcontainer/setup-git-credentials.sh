#!/bin/bash

# Setup Git credentials for GitHub authentication
# This script runs once per container session to configure git credential store

set -e

# Check if GITHUB_TOKEN is available
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Warning: GITHUB_TOKEN not set. Git authentication will not be configured." >&2
    exit 0
fi

# Get GitHub username via API
echo "Setting up Git credentials for GitHub..." >&2
GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user 2>/dev/null | jq -r '.login' 2>/dev/null)

# Validate username
if [ -z "$GITHUB_USER" ] || [ "$GITHUB_USER" = "null" ]; then
    echo "Error: Could not retrieve GitHub username. Check GITHUB_TOKEN validity." >&2
    exit 1
fi

# Create git credentials file
echo "https://$GITHUB_USER:$GITHUB_TOKEN@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials

# Setup GitHub CLI authentication
echo "$GITHUB_TOKEN" | gh auth login --with-token >/dev/null 2>&1

echo "✓ Git credentials configured for user: $GITHUB_USER" >&2
echo "✓ GitHub CLI authenticated" >&2