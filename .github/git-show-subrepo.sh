#!/bin/bash

# Git Show Subrepo Script
# Usage: ./git-show-subrepo.sh <subrepo-name>
# Example: ./git-show-subrepo.sh meowtopia

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

echo "Showing subrepo: $SUBREPO_NAME"

# Remove the subrepo from .gitignore if it exists
if grep -q "apps/$SUBREPO_NAME" .gitignore; then
    echo "Removing $SUBREPO_NAME from .gitignore..."
    sed -i "/apps\/$SUBREPO_NAME/d" .gitignore
    echo "✓ Removed $SUBREPO_NAME from .gitignore"
else
    echo "✓ $SUBREPO_NAME is not hidden in .gitignore"
fi

# Add the subrepo to git if it's not already tracked
if ! git ls-files --error-unmatch "apps/$SUBREPO_NAME" >/dev/null 2>&1; then
    echo "Adding $SUBREPO_NAME to git tracking..."
    git add "apps/$SUBREPO_NAME"
    echo "✓ Added $SUBREPO_NAME to git tracking"
else
    echo "✓ $SUBREPO_NAME is already tracked by git"
fi

echo "Subrepo '$SUBREPO_NAME' is now visible and tracked by git"
