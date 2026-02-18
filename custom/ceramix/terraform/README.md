# Ceramix Terraform Configuration

Terraform configuration for automatically managing Ceramix Docker containers.

## Features

- **Automatic container updates**: Terraform detects changes in Dockerfile, entrypoint.sh, and package.json and rebuilds/restarts containers
- **Infrastructure as Code**: All container configuration is version-controlled
- **Hot reload support**: Volume mounts enable hot reload for development

## Usage

### Initial Setup

```bash
cd .project/ceramix/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### Apply Changes

```bash
# Initialize Terraform (first time only)
terraform init

# Plan changes (see what will change)
terraform plan

# Apply changes (rebuild and restart containers)
terraform apply
```

### Automatic Updates

When you modify:
- `../web/Dockerfile` → Container will be rebuilt
- `../web/entrypoint.sh` → Container will be rebuilt
- `../web/package.json` → Container will be rebuilt
- Any Terraform files → Container will be recreated

### Watch Mode (Alternative)

For manual Docker Compose setup with watch script:

```bash
# In project root
chmod +x .project/ceramix/scripts/watch-and-reload.sh
.project/ceramix/scripts/watch-and-reload.sh
```

This script monitors config files and automatically restarts containers when they change.

## Hot Reload vs Restart

### Hot Reload (Automatic, No Restart)
These changes are picked up automatically by Next.js HMR:
- TypeScript/TSX files
- CSS files
- Most React component changes
- API route changes (sometimes requires page refresh)

### Requires Container Restart
These changes require container rebuild/restart:
- `Dockerfile` changes
- `entrypoint.sh` changes
- `package.json` changes (new dependencies)
- Environment variable changes (`.env` files)
- `docker-compose.yml` changes
- `next.config.js` changes (sometimes)

## Integration with CI/CD

Terraform can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Deploy with Terraform
  run: |
    cd .project/ceramix/terraform
    terraform init
    terraform apply -auto-approve
```










































