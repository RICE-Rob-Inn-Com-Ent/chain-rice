# Git Subrepo Management

This directory contains scripts to manage subrepos in the `apps/` directory. These scripts allow you to show/hide subrepos from git tracking and visibility, as well as push/pull operations with remote repositories.

## Available Scripts

### Main Manager Script
- **`git-subrepo-manager.sh`** - Main script for all subrepo operations

### Individual Scripts
- **`git-show-subrepo.sh`** - Show a specific subrepo
- **`git-hide-subrepo.sh`** - Hide a specific subrepo  
- **`git-push-subrepo.sh`** - Push subrepo to remote and remove from local PC
- **`git-pull-subrepo.sh`** - Pull subrepo from remote and download to local PC
- **`git-subrepo-status.sh`** - Show status of all subrepos

## Usage

### Using the Main Manager Script

```bash
# Show help
./.github/git-subrepo-manager.sh help

# Show status of all subrepos
./.github/git-subrepo-manager.sh status

# Show a specific subrepo (make it visible and tracked)
./.github/git-subrepo-manager.sh show meowtopia
./.github/git-subrepo-manager.sh show chain-rice

# Hide a specific subrepo (add to .gitignore, remove from tracking)
./.github/git-subrepo-manager.sh hide meowtopia
./.github/git-subrepo-manager.sh hide chain-rice

# Push a specific subrepo to its remote repo and remove from local PC
./.github/git-subrepo-manager.sh push meowtopia
./.github/git-subrepo-manager.sh push chain-rice

# Pull a specific subrepo from its remote repo and download to local PC
./.github/git-subrepo-manager.sh pull meowtopia
./.github/git-subrepo-manager.sh pull chain-rice

# Show all subrepos at once
./.github/git-subrepo-manager.sh show-all

# Hide all subrepos at once
./.github/git-subrepo-manager.sh hide-all

# Push all subrepos to their remote repos
./.github/git-subrepo-manager.sh push-all

# Pull all subrepos from their remote repos
./.github/git-subrepo-manager.sh pull-all
```

### Using Individual Scripts

```bash
# Show a specific subrepo
./.github/git-show-subrepo.sh meowtopia
./.github/git-show-subrepo.sh chain-rice

# Hide a specific subrepo
./.github/git-hide-subrepo.sh meowtopia
./.github/git-hide-subrepo.sh chain-rice

# Push a specific subrepo to remote and remove from local PC
./.github/git-push-subrepo.sh meowtopia
./.github/git-push-subrepo.sh chain-rice

# Pull a specific subrepo from remote and download to local PC
./.github/git-pull-subrepo.sh meowtopia
./.github/git-pull-subrepo.sh chain-rice

# Check status
./.github/git-subrepo-status.sh
```

## What These Scripts Do

### Show Subrepo (`show` command)
1. Removes the subrepo from `.gitignore` (if present)
2. Adds the subrepo to git tracking
3. Makes the subrepo visible in git status and commits

### Hide Subrepo (`hide` command)
1. Adds the subrepo to `.gitignore`
2. Removes the subrepo from git tracking (using `git rm --cached`)
3. Makes the subrepo invisible to git operations

### Push Subrepo (`push` command)
1. Initializes git repository in the subrepo (if not already a git repo)
2. Adds remote origin pointing to the subrepo's remote repository
3. Commits all changes in the subrepo
4. Pushes the subrepo to its remote repository
5. Hides the subrepo from the main repository
6. **Removes the subrepo directory from your local PC**

### Pull Subrepo (`pull` command)
1. Clones the subrepo from its remote repository
2. Downloads it to `apps/<subrepo-name>/`
3. Shows the subrepo (makes it visible and tracked)
4. **Makes the subrepo available locally for development**

### Status (`status` command)
Shows detailed information about each subrepo:
- Whether the directory exists locally
- Visibility status (hidden/visible)
- Git tracking status
- Remote repository information (if it's a git repo)
- Last commit information
- Whether the subrepo is available remotely

## Available Subrepos

Currently configured subrepos with their remote repositories:
- `meowtopia` - Located in `apps/meowtopia/` → `https://github.com/RICE-Rob-Inn-Com-Ent/meowtopia.git`
- `chain-rice` - Located in `apps/chain-rice/` → `https://github.com/RICE-Rob-Inn-Com-Ent/chain-rice.git`

## Examples

```bash
# Check current status
./.github/git-subrepo-manager.sh status

# Hide meowtopia subrepo
./.github/git-subrepo-manager.sh hide meowtopia

# Show chain-rice subrepo
./.github/git-subrepo-manager.sh show chain-rice

# Push meowtopia to remote and remove from local PC
./.github/git-subrepo-manager.sh push meowtopia

# Pull chain-rice from remote and download to local PC
./.github/git-subrepo-manager.sh pull chain-rice

# Hide all subrepos
./.github/git-subrepo-manager.sh hide-all

# Show all subrepos
./.github/git-subrepo-manager.sh show-all

# Push all subrepos to their remotes
./.github/git-subrepo-manager.sh push-all

# Pull all subrepos from their remotes
./.github/git-subrepo-manager.sh pull-all
```

## GitHub Actions Integration

The subrepo management scripts are integrated with GitHub Actions workflows:

### Workflows

1. **`deploy-master.yml`** - Deploys master branch with subrepo integration
   - Pulls all subrepos
   - Builds chain-rice and meowtopia
   - Deploys with Docker
   - Pushes subrepos back to remotes

2. **`release.yml`** - Creates releases for subrepos
   - Triggered by tags: `v<subrepo>-<version>` (e.g., `vchain-rice-1.0.0`)
   - Pulls specific subrepo based on tag
   - Builds and packages the subrepo
   - Creates GitHub release with built assets

3. **`chain-rice.yml`** - Individual workflow for chain-rice
   - Triggers on changes to `apps/chain-rice/**`
   - Builds and tests chain-rice
   - Pushes changes back to remote

4. **`meowtopia.yml`** - Individual workflow for meowtopia
   - Triggers on changes to `apps/meowtopia/**`
   - Builds and tests meowtopia
   - Pushes changes back to remote

5. **`version-manager.yml`** - Version management workflow
   - Manual trigger for version operations
   - Supports bump-patch, bump-minor, bump-major
   - Reads versions from package.json (meowtopia) and go.mod (chain-rice)

6. **`subrepo-sync.yml`** - Synchronization workflow
   - Runs every 6 hours to sync subrepos
   - Manual trigger for sync operations
   - Builds and tests all subrepos

### Tag-based Releases

To create a release for a specific subrepo:

```bash
# For chain-rice version 1.2.3
git tag vchain-rice-1.2.3
git push origin vchain-rice-1.2.3

# For meowtopia version 2.1.0
git tag vmeowtopia-2.1.0
git push origin vmeowtopia-2.1.0
```

## Notes

- These scripts work by manipulating `.gitignore` and git tracking
- Hidden subrepos are not deleted, just ignored by git
- You can still work with hidden subrepos normally, they just won't appear in git operations
- The scripts are safe to run multiple times (idempotent)
- **Push operations**: Pushes the subrepo to its remote repository and removes it from your local PC
- **Pull operations**: Downloads the subrepo from its remote repository and makes it available locally
- Remote repositories are configured in the scripts and point to the RICE-Rob-Inn-Com-Ent organization
- Make sure you have proper access to the remote repositories before using push/pull operations
- **GitHub Actions**: All workflows automatically use the subrepo management scripts
- **Version Management**: Use the version-manager workflow to bump versions in subrepos
- **Automatic Sync**: Subrepos are automatically synced every 6 hours
