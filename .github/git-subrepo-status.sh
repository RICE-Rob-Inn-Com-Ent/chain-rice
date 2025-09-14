#!/bin/bash

# Git Subrepo Status Script
# Shows the current status of all subrepos

echo "=== Subrepo Status ==="
echo

# Check each subrepo
for subrepo in meowtopia chain-rice; do
    echo "📁 $subrepo:"
    
    # Check if directory exists
    if [ -d "apps/$subrepo" ]; then
        echo "  ✓ Directory exists"
        
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
        echo "  ❌ Directory does not exist"
    fi
    echo
done

echo "=== Available Commands ==="
echo "Show subrepo:  ./.github/git-show-subrepo.sh <name>"
echo "Hide subrepo:  ./.github/git-hide-subrepo.sh <name>"
echo "Status:        ./.github/git-subrepo-status.sh"
