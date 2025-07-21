#!/bin/bash

# GitHub authentication setup script
# Runs once at container startup to configure git and GitHub CLI

if [ -n "$GITHUB_TOKEN" ]; then
    echo "Setting up GitHub authentication..."
    
    # Configure git to use token for all GitHub URLs
    git config --global url."https://$GITHUB_TOKEN@github.com/".insteadOf "https://github.com/" 2>/dev/null || true
    
    # Authenticate GitHub CLI
    echo "$GITHUB_TOKEN" | gh auth login --with-token >/dev/null 2>&1 || true
    
    echo "GitHub authentication configured."
else
    echo "No GITHUB_TOKEN provided - skipping GitHub authentication setup."
fi