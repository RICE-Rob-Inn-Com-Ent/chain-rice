#!/bin/bash

# Auto-commit script for rice-mono projects
# Monitors the active project for changes and commits automatically

REPO_ROOT="$HOME/rice-mono"
PROJECT_DIR="$REPO_ROOT/.project"
COMMIT_INTERVAL=30 # seconds

function get_active_project() {
  cat "$REPO_ROOT/.project-active"
}

function get_project_repo() {
  local project=$(get_active_project)
  if [ "$project" == "code_rice" ]; then
    echo "$PROJECT_DIR"
  else
    echo "$REPO_ROOT"
  fi
}

function commit_project() {
  local repo_path=$(get_project_repo)
  local project=$(get_active_project)

  cd "$repo_path" || return 1

  # Check if there are changes
  if git diff --quiet && git diff --cached --quiet; then
    return 0
  fi

  # Stage all changes
  git add -A

  # Check if there are staged changes
  if git diff --cached --quiet; then
    return 0
  fi

  # Commit with timestamp
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local branch=$(git branch --show-current)

  git commit -m "chore: auto-commit at $timestamp [branch: $branch]"

  return $?
}

function push_changes() {
  local repo_path=$(get_project_repo)

  cd "$repo_path" || return 1

  # Get current branch
  local branch=$(git branch --show-current)

  # Push to remote
  git push origin $branch 2>&1 | grep -v "already up to date" || true
}

# Main loop
while true; do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for changes..."

  if commit_project; then
    echo "No changes to commit"
  else
    echo "Changes committed"
    push_changes
  fi

  sleep $COMMIT_INTERVAL
done
