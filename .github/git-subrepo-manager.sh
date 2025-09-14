#!/bin/bash

# Git Subrepo Manager Script
# Usage: ./git-subrepo-manager.sh <command> [subrepo-name]
# Commands: show, hide, status, show-all, hide-all, push, pull, push-all, pull-all

set -e

COMMAND="$1"
SUBREPO_NAME="$2"

# Available subrepos with their remote repositories
declare -A SUBREPO_REMOTES=(
    ["meowtopia"]="https://github.com/RICE-Rob-Inn-Com-Ent/meowtopia.git"
    ["chain-rice"]="https://github.com/RICE-Rob-Inn-Com-Ent/chain-rice.git"
)

# Available subrepos
AVAILABLE_SUBREPOS=("meowtopia" "chain-rice")

show_help() {
    echo "Git Subrepo Manager"
    echo "Usage: $0 <command> [subrepo-name]"
    echo
    echo "Commands:"
    echo "  show <name>     - Show a specific subrepo (make it visible and tracked)"
    echo "  hide <name>     - Hide a specific subrepo (add to .gitignore, remove from tracking)"
    echo "  push <name>     - Push subrepo to its remote repo and remove from local PC"
    echo "  pull <name>     - Pull subrepo from its remote repo and download to local PC"
    echo "  status          - Show status of all subrepos"
    echo "  show-all        - Show all subrepos"
    echo "  hide-all        - Hide all subrepos"
    echo "  push-all        - Push all subrepos to their remote repos"
    echo "  pull-all        - Pull all subrepos from their remote repos"
    echo "  help            - Show this help message"
    echo
    echo "Available subrepos: ${AVAILABLE_SUBREPOS[*]}"
    echo
    echo "Remote repositories:"
    for subrepo in "${AVAILABLE_SUBREPOS[@]}"; do
        echo "  $subrepo: ${SUBREPO_REMOTES[$subrepo]}"
    done
    echo
    echo "Examples:"
    echo "  $0 show meowtopia"
    echo "  $0 hide chain-rice"
    echo "  $0 push meowtopia"
    echo "  $0 pull chain-rice"
    echo "  $0 status"
    echo "  $0 push-all"
    echo "  $0 pull-all"
}

show_subrepo() {
    local subrepo="$1"
    
    if [ -z "$subrepo" ]; then
        echo "Error: Subrepo name required for 'show' command"
        show_help
        exit 1
    fi
    
    # Check if subrepo exists in apps directory
    if [ ! -d "apps/$subrepo" ]; then
        echo "Error: Subrepo '$subrepo' not found in apps/ directory"
        exit 1
    fi
    
    echo "Showing subrepo: $subrepo"
    
    # Remove the subrepo from .gitignore if it exists
    if grep -q "apps/$subrepo" .gitignore; then
        echo "Removing $subrepo from .gitignore..."
        sed -i "/apps\/$subrepo/d" .gitignore
        echo "✓ Removed $subrepo from .gitignore"
    else
        echo "✓ $subrepo is not hidden in .gitignore"
    fi
    
    # Add the subrepo to git if it's not already tracked
    if ! git ls-files --error-unmatch "apps/$subrepo" >/dev/null 2>&1; then
        echo "Adding $subrepo to git tracking..."
        git add "apps/$subrepo"
        echo "✓ Added $subrepo to git tracking"
    else
        echo "✓ $subrepo is already tracked by git"
    fi
    
    echo "Subrepo '$subrepo' is now visible and tracked by git"
}

hide_subrepo() {
    local subrepo="$1"
    
    if [ -z "$subrepo" ]; then
        echo "Error: Subrepo name required for 'hide' command"
        show_help
        exit 1
    fi
    
    # Check if subrepo exists in apps directory
    if [ ! -d "apps/$subrepo" ]; then
        echo "Error: Subrepo '$subrepo' not found in apps/ directory"
        exit 1
    fi
    
    echo "Hiding subrepo: $subrepo"
    
    # Add the subrepo to .gitignore if it doesn't exist
    if ! grep -q "apps/$subrepo" .gitignore; then
        echo "Adding $subrepo to .gitignore..."
        echo "apps/$subrepo" >> .gitignore
        echo "✓ Added $subrepo to .gitignore"
    else
        echo "✓ $subrepo is already hidden in .gitignore"
    fi
    
    # Remove the subrepo from git tracking if it's tracked
    if git ls-files --error-unmatch "apps/$subrepo" >/dev/null 2>&1; then
        echo "Removing $subrepo from git tracking..."
        git rm -r --cached "apps/$subrepo" 2>/dev/null || true
        echo "✓ Removed $subrepo from git tracking"
    else
        echo "✓ $subrepo is not tracked by git"
    fi
    
    echo "Subrepo '$subrepo' is now hidden from git"
}

push_subrepo() {
    local subrepo="$1"
    
    if [ -z "$subrepo" ]; then
        echo "Error: Subrepo name required for 'push' command"
        show_help
        exit 1
    fi
    
    # Check if subrepo exists in apps directory
    if [ ! -d "apps/$subrepo" ]; then
        echo "Error: Subrepo '$subrepo' not found in apps/ directory"
        exit 1
    fi
    
    local remote_url="${SUBREPO_REMOTES[$subrepo]}"
    if [ -z "$remote_url" ]; then
        echo "Error: No remote repository configured for '$subrepo'"
        exit 1
    fi
    
    echo "Pushing subrepo: $subrepo to $remote_url"
    
    # Navigate to subrepo directory
    cd "apps/$subrepo"
    
    # Check if it's a git repository
    if [ ! -d ".git" ]; then
        echo "Initializing git repository for $subrepo..."
        git init
        git add .
        git commit -m "Initial commit for $subrepo"
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
        git commit -m "Update $subrepo - $(date)"
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
    echo "Hiding $subrepo from main repository..."
    hide_subrepo "$subrepo"
    
    # Remove the local directory
    echo "Removing local directory..."
    rm -rf "apps/$subrepo"
    
    echo "✓ Subrepo '$subrepo' has been pushed to remote and removed from local PC"
}

pull_subrepo() {
    local subrepo="$1"
    
    if [ -z "$subrepo" ]; then
        echo "Error: Subrepo name required for 'pull' command"
        show_help
        exit 1
    fi
    
    local remote_url="${SUBREPO_REMOTES[$subrepo]}"
    if [ -z "$remote_url" ]; then
        echo "Error: No remote repository configured for '$subrepo'"
        exit 1
    fi
    
    echo "Pulling subrepo: $subrepo from $remote_url"
    
    # Check if directory already exists
    if [ -d "apps/$subrepo" ]; then
        echo "Directory 'apps/$subrepo' already exists. Removing it first..."
        rm -rf "apps/$subrepo"
    fi
    
    # Create apps directory if it doesn't exist
    mkdir -p apps
    
    # Clone the repository
    echo "Cloning repository..."
    git clone "$remote_url" "apps/$subrepo"
    
    # Show the subrepo (make it visible and tracked)
    echo "Making $subrepo visible..."
    show_subrepo "$subrepo"
    
    echo "✓ Subrepo '$subrepo' has been pulled from remote and is now available locally"
}

show_all_subrepos() {
    echo "Showing all subrepos..."
    for subrepo in "${AVAILABLE_SUBREPOS[@]}"; do
        if [ -d "apps/$subrepo" ]; then
            echo "--- Showing $subrepo ---"
            show_subrepo "$subrepo"
            echo
        fi
    done
}

hide_all_subrepos() {
    echo "Hiding all subrepos..."
    for subrepo in "${AVAILABLE_SUBREPOS[@]}"; do
        if [ -d "apps/$subrepo" ]; then
            echo "--- Hiding $subrepo ---"
            hide_subrepo "$subrepo"
            echo
        fi
    done
}

push_all_subrepos() {
    echo "Pushing all subrepos..."
    for subrepo in "${AVAILABLE_SUBREPOS[@]}"; do
        if [ -d "apps/$subrepo" ]; then
            echo "--- Pushing $subrepo ---"
            push_subrepo "$subrepo"
            echo
        else
            echo "--- Skipping $subrepo (not present locally) ---"
        fi
    done
}

pull_all_subrepos() {
    echo "Pulling all subrepos..."
    for subrepo in "${AVAILABLE_SUBREPOS[@]}"; do
        echo "--- Pulling $subrepo ---"
        pull_subrepo "$subrepo"
        echo
    done
}

show_status() {
    echo "=== Subrepo Status ==="
    echo
    
    # Check each subrepo
    for subrepo in "${AVAILABLE_SUBREPOS[@]}"; do
        echo "📁 $subrepo:"
        
        # Check if directory exists
        if [ -d "apps/$subrepo" ]; then
            echo "  ✓ Directory exists locally"
            
            # Check if it's in .gitignore
            if grep -q "apps/$subrepo" .gitignore; then
                echo "  👁️  Status: HIDDEN (in .gitignore)"
            else
                echo "  👁️  Status: VISIBLE (not in .gitignore)"
            fi
            
            # Check if it's tracked by git
            if git ls-files --error-unmatch "apps/$subrepo" >/dev/null 2>&1; then
                echo "  📝 Git: TRACKED"
            else
                echo "  📝 Git: NOT TRACKED"
            fi
            
            # Show last commit info if it's a git repo
            if [ -d "apps/$subrepo/.git" ]; then
                cd "apps/$subrepo"
                if git rev-parse --git-dir > /dev/null 2>&1; then
                    echo "  🔗 Remote: $(git remote get-url origin 2>/dev/null || echo 'No remote')"
                    echo "  📅 Last commit: $(git log -1 --format='%h - %s (%cr)' 2>/dev/null || echo 'No commits')"
                fi
                cd - > /dev/null
            fi
        else
            echo "  ❌ Directory does not exist locally"
            echo "  🌐 Remote: ${SUBREPO_REMOTES[$subrepo]}"
            echo "  💡 Use 'pull $subrepo' to download it"
        fi
        echo
    done
}

# Main command handling
case "$COMMAND" in
    "show")
        show_subrepo "$SUBREPO_NAME"
        ;;
    "hide")
        hide_subrepo "$SUBREPO_NAME"
        ;;
    "push")
        push_subrepo "$SUBREPO_NAME"
        ;;
    "pull")
        pull_subrepo "$SUBREPO_NAME"
        ;;
    "status")
        show_status
        ;;
    "show-all")
        show_all_subrepos
        ;;
    "hide-all")
        hide_all_subrepos
        ;;
    "push-all")
        push_all_subrepos
        ;;
    "pull-all")
        pull_all_subrepos
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_help
        exit 1
        ;;
esac