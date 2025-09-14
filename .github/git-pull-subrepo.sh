#!/bin/bash

# Git Pull Subrepo Script
# Usage: ./git-pull-subrepo.sh <subrepo-name>
# Example: ./git-pull-subrepo.sh meowtopia

set -e

SUBREPO_NAME="$1"

if [ -z "$SUBREPO_NAME" ]; then
    echo "Usage: $0 <subrepo-name>"
    echo "Available subrepos: meowtopia, chain-rice"
    exit 1
fi

# Remote repositories
declare -A SUBREPO_REMOTES=(
    ["meowtopia"]="https://github.com/RICE-Rob-Inn-Com-Ent/meowtopia.git"
    ["chain-rice"]="https://github.com/RICE-Rob-Inn-Com-Ent/chain-rice.git"
)

remote_url="${SUBREPO_REMOTES[$SUBREPO_NAME]}"
if [ -z "$remote_url" ]; then
    echo "Error: No remote repository configured for '$SUBREPO_NAME'"
    exit 1
fi

echo "📥 Pulling subrepo: $SUBREPO_NAME from $remote_url"

# Check if directory already exists
if [ -d "apps/$SUBREPO_NAME" ]; then
    echo "Directory 'apps/$SUBREPO_NAME' already exists. Removing it first..."
    rm -rf "apps/$SUBREPO_NAME"
fi

# Create apps directory if it doesn't exist
mkdir -p apps

# Clone the repository
echo "Cloning repository..."
git clone "$remote_url" "apps/$SUBREPO_NAME"

# Remove the subrepo from .gitignore if it exists
if grep -q "apps/$SUBREPO_NAME" .gitignore; then
    echo "Removing $SUBREPO_NAME from .gitignore..."
    sed -i "/apps\/$SUBREPO_NAME/d" .gitignore
fi

# Add the subrepo to git if it's not already tracked
if ! git ls-files --error-unmatch "apps/$SUBREPO_NAME" >/dev/null 2>&1; then
    echo "Adding $SUBREPO_NAME to git tracking..."
    git add "apps/$SUBREPO_NAME"
fi

echo "✅ Subrepo '$SUBREPO_NAME' has been pulled from remote and is now available locally"
echo "💡 Use './.github/git-push-subrepo.sh $SUBREPO_NAME' to push changes back"
