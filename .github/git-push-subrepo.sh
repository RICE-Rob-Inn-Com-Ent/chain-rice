#!/bin/bash

# Git Push Subrepo Script
# Usage: ./git-push-subrepo.sh <subrepo-name>
# Example: ./git-push-subrepo.sh meowtopia

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

# Check if subrepo exists in apps directory
if [ ! -d "apps/$SUBREPO_NAME" ]; then
    echo "Error: Subrepo '$SUBREPO_NAME' not found in apps/ directory"
    exit 1
fi

remote_url="${SUBREPO_REMOTES[$SUBREPO_NAME]}"
if [ -z "$remote_url" ]; then
    echo "Error: No remote repository configured for '$SUBREPO_NAME'"
    exit 1
fi

echo "🚀 Pushing subrepo: $SUBREPO_NAME to $remote_url"

# Navigate to subrepo directory
cd "apps/$SUBREPO_NAME"

# Check if it's a git repository
if [ ! -d ".git" ]; then
    echo "Initializing git repository for $SUBREPO_NAME..."
    git init
    git add .
    git commit -m "Initial commit for $SUBREPO_NAME"
fi

# Add remote if it doesn't exist
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "Adding remote origin: $remote_url"
    git remote add origin "$remote_url"
else
    echo "Remote origin already exists"
fi

# Add all changes and commit if there are uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Committing changes..."
    git add .
    git commit -m "Update $SUBREPO_NAME - $(date)"
fi

# Push to remote repository
echo "Pushing to remote repository..."
git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || {
    echo "Creating main branch and pushing..."
    git branch -M main
    git push -u origin main
}

# Go back to parent directory
cd - > /dev/null

# Now hide the subrepo from the main repository
echo "Hiding $SUBREPO_NAME from main repository..."
if ! grep -q "apps/$SUBREPO_NAME" .gitignore; then
    echo "apps/$SUBREPO_NAME" >> .gitignore
fi

# Remove the subrepo from git tracking if it's tracked
if git ls-files --error-unmatch "apps/$SUBREPO_NAME" >/dev/null 2>&1; then
    git rm -r --cached "apps/$SUBREPO_NAME" 2>/dev/null || true
fi

# Remove the local directory
echo "Removing local directory..."
rm -rf "apps/$SUBREPO_NAME"

echo "✅ Subrepo '$SUBREPO_NAME' has been pushed to remote and removed from local PC"
echo "💡 Use './.github/git-pull-subrepo.sh $SUBREPO_NAME' to download it back"
