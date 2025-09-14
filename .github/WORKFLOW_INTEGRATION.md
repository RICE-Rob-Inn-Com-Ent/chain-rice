# GitHub Actions Workflow Integration

This document explains how the subrepo management scripts are integrated with GitHub Actions workflows.

## Overview

The subrepo management system is fully integrated with GitHub Actions, allowing for:
- Automatic deployment with subrepo handling
- Tag-based releases for individual subrepos
- Version management across subrepos
- Automatic synchronization and building

## Workflow Files

### 1. `deploy-master.yml`
**Purpose**: Deploys the master branch with full subrepo integration

**Triggers**: Push to `master` branch

**Process**:
1. Pulls all subrepos using `git-subrepo-manager.sh pull-all`
2. Builds chain-rice using `make build`
3. Builds meowtopia using `yarn install && yarn build`
4. Builds Docker images
5. Deploys with Docker Compose
6. Pushes all subrepos back to their remotes

### 2. `release.yml`
**Purpose**: Creates releases for specific subrepos based on tags

**Triggers**: Push tags matching `v*-*` pattern

**Tag Format**: `v<subrepo>-<version>`
- `vchain-rice-1.0.0` - Releases chain-rice version 1.0.0
- `vmeowtopia-2.1.0` - Releases meowtopia version 2.1.0

**Process**:
1. Parses tag to extract subrepo and version
2. Pulls the specific subrepo
3. Builds the subrepo (chain-rice or meowtopia)
4. Creates release archive
5. Publishes GitHub release with built assets
6. Pushes subrepo back to remote

### 3. `chain-rice.yml`
**Purpose**: Individual workflow for chain-rice subrepo

**Triggers**: 
- Push to `master` or `development` branches
- Changes to `apps/chain-rice/**` path
- Pull requests to `master` or `development` branches

**Process**:
1. Pulls chain-rice subrepo
2. Sets up Go environment
3. Builds chain-rice
4. Runs tests (if configured)
5. Pushes changes back to remote

### 4. `meowtopia.yml`
**Purpose**: Individual workflow for meowtopia subrepo

**Triggers**:
- Push to `master` or `development` branches
- Changes to `apps/meowtopia/**` path
- Pull requests to `master` or `development` branches

**Process**:
1. Pulls meowtopia subrepo
2. Sets up Node.js environment
3. Installs dependencies with `yarn install --frozen-lockfile`
4. Builds meowtopia
5. Runs tests (if configured)
6. Pushes changes back to remote

### 5. `version-manager.yml`
**Purpose**: Version management for subrepos

**Triggers**: Manual workflow dispatch

**Actions**:
- `bump-patch` - Increment patch version (1.0.0 → 1.0.1)
- `bump-minor` - Increment minor version (1.0.0 → 1.1.0)
- `bump-major` - Increment major version (1.0.0 → 2.0.0)
- `set-version` - Set custom version
- `get-version` - Get current version

**Version Sources**:
- **chain-rice**: Reads from `go.mod` or creates `VERSION` file
- **meowtopia**: Reads from `package.json`

### 6. `subrepo-sync.yml`
**Purpose**: Automatic synchronization of subrepos

**Triggers**:
- Every 6 hours (cron schedule)
- Manual workflow dispatch

**Actions**:
- `sync-all` - Pull, build, test, and push all subrepos
- `pull-all` - Pull all subrepos
- `push-all` - Push all subrepos
- `status` - Check status of all subrepos

## Usage Examples

### Creating a Release

```bash
# Create and push a tag for chain-rice version 1.2.3
git tag vchain-rice-1.2.3
git push origin vchain-rice-1.2.3

# Create and push a tag for meowtopia version 2.1.0
git tag vmeowtopia-2.1.0
git push origin vmeowtopia-2.1.0
```

### Version Management

1. Go to GitHub Actions → Workflows
2. Select "Version Manager for Subrepos"
3. Click "Run workflow"
4. Choose subrepo, action, and custom version (if needed)
5. Click "Run workflow"

### Manual Synchronization

1. Go to GitHub Actions → Workflows
2. Select "Subrepo Synchronization"
3. Click "Run workflow"
4. Choose action (sync-all, pull-all, push-all, status)
5. Click "Run workflow"

## Configuration

### Remote Repositories

The subrepo management scripts are configured with these remote repositories:
- **meowtopia**: `https://github.com/RICE-Rob-Inn-Com-Ent/meowtopia.git`
- **chain-rice**: `https://github.com/RICE-Rob-Inn-Com-Ent/chain-rice.git`

### Build Commands

- **chain-rice**: `make build` (Go project)
- **meowtopia**: `yarn install && yarn build` (Node.js project)

### Docker Integration

The deploy workflow uses Docker for deployment:
- Builds images with `docker buildx bake`
- Deploys with `docker compose --profile blockchain --profile app up -d`

## Benefits

1. **Automated Deployment**: Master branch automatically deploys with subrepo integration
2. **Individual Releases**: Each subrepo can be released independently
3. **Version Management**: Centralized version bumping and management
4. **Automatic Sync**: Regular synchronization ensures subrepos stay up-to-date
5. **Build Integration**: Automatic building and testing of subrepos
6. **Docker Integration**: Seamless Docker deployment with subrepo support

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure GitHub Actions has proper permissions
2. **Build Failures**: Check that build commands are correct in subrepos
3. **Push Failures**: Verify remote repository access
4. **Version Conflicts**: Use version-manager workflow to resolve conflicts

### Debugging

- Check GitHub Actions logs for detailed error messages
- Use the status action to check subrepo state
- Verify remote repository URLs and access
- Ensure build commands work locally before pushing
