#!/bin/bash

# Git Hide Subrepo Script
# Usage: ./git-hide-subrepo.sh <subrepo-name>
# Example: ./git-hide-subrepo.sh meowtopia

set -e

SUBREPO_NAME="$1"

if [ -z "$SUBREPO_NAME" ]; then
    echo "Usage: $0 <subrepo-name>"
    echo "Available subrepos: meowtopia, chain-rice"
    exit 1
fi

# Check if subrepo exists in apps directory
if [ ! -d "apps/$SUBREPO_NAME" ]; then
    echo "Error: Subrepo '$SUBREPO_NAME' not found in apps/ directory"
    exit 1
fi

echo "Hiding subrepo: $SUBREPO_NAME"

# Add the subrepo to .gitignore if it doesn't exist
if ! grep -q "apps/$SUBREPO_NAME" .gitignore; then
    echo "Adding $SUBREPO_NAME to .gitignore..."
    echo "apps/$SUBREPO_NAME" >> .gitignore
    echo "✓ Added $SUBREPO_NAME to .gitignore"
else
    echo "✓ $SUBREPO_NAME is already hidden in .gitignore"
fi

# Remove the subrepo from git tracking if it's tracked
if git ls-files --error-unmatch "apps/$SUBREPO_NAME" >/dev/null 2>&1; then
    echo "Removing $SUBREPO_NAME from git tracking..."
    git rm -r --cached "apps/$SUBREPO_NAME" 2>/dev/null || true
    echo "✓ Removed $SUBREPO_NAME from git tracking"
else
    echo "✓ $SUBREPO_NAME is not tracked by git"
fi

echo "Subrepo '$SUBREPO_NAME' is now hidden from git"
