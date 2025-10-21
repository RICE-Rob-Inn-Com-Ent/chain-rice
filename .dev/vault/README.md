# HashiCorp Vault - Secrets Management

## Overview

HashiCorp Vault secures, stores, and tightly controls access to secrets across distributed infrastructure and
applications.

## Features

- ✅ **Secret Storage** - Secure storage for API keys, passwords, certificates
- ✅ **Dynamic Secrets** - Generate secrets on-demand
- ✅ **Data Encryption** - Encrypt/decrypt data without storing it
- ✅ **Lease & Revocation** - Time-limited access with automatic revocation
- ✅ **Audit Logging** - Complete audit trail
- ✅ **Multi-Cloud** - Works across AWS, Azure, GCP, K8s

## Quick Start

### 1. Run Vault in Development Mode

```bash
# Start Vault dev server
docker-compose up -d vault

# Get root token
docker logs vault 2>&1 | grep "Root Token"

# Export Vault address
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='<root-token>'
```

### 2. Enable Secrets Engine

```bash
# Enable KV secrets engine
vault secrets enable -version=2 kv

# Write a secret
vault kv put kv/app/config \
  db_password=supersecret \
  api_key=myapikey123

# Read a secret
vault kv get kv/app/config
```

### 3. Use in Application

#### Python Example

```python
import hvac

client = hvac.Client(
    url='http://localhost:8200',
    token='your-vault-token'
)

# Read secret
secret = client.secrets.kv.v2.read_secret_version(
    path='app/config',
    mount_point='kv'
)

db_password = secret['data']['data']['db_password']
```

#### Go Example

```go
import (
    vault "github.com/hashicorp/vault/api"
)

client, _ := vault.NewClient(&vault.Config{
    Address: "http://localhost:8200",
})
client.SetToken("your-vault-token")

secret, _ := client.Logical().Read("kv/data/app/config")
dbPassword := secret.Data["data"].(map[string]interface{})["db_password"]
```

## Kubernetes Integration

### Vault Agent Injector

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "app-role"
        vault.hashicorp.com/agent-inject-secret-config: "kv/data/app/config"
        vault.hashicorp.com/agent-inject-template-config: |
          {{- with secret "kv/data/app/config" -}}
          DB_PASSWORD={{ .Data.data.db_password }}
          API_KEY={{ .Data.data.api_key }}
          {{- end }}
    spec:
      serviceAccountName: app
      containers:
        - name: app
          image: myapp:latest
          command: ["sh", "-c", "source /vault/secrets/config && ./app"]
```

## Dynamic Database Credentials

```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="app-role" \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/mydb" \
    username="vault" \
    password="vault-password"

# Create role
vault write database/roles/app-role \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

# Generate credentials
vault read database/creds/app-role
```

## PKI (Certificate Authority)

```bash
# Enable PKI
vault secrets enable pki

# Configure CA
vault write pki/root/generate/internal \
    common_name="myapp.com" \
    ttl=87600h

# Create role
vault write pki/roles/myapp \
    allowed_domains="myapp.com" \
    allow_subdomains=true \
    max_ttl="720h"

# Issue certificate
vault write pki/issue/myapp \
    common_name="api.myapp.com"
```

## Policies

```hcl
# app-policy.hcl
path "kv/data/app/*" {
  capabilities = ["read", "list"]
}

path "database/creds/app-role" {
  capabilities = ["read"]
}

path "pki/issue/myapp" {
  capabilities = ["create", "update"]
}
```

Apply policy:

```bash
vault policy write app-policy app-policy.hcl
```

## Authentication Methods

### AppRole (for applications)

```bash
# Enable AppRole
vault auth enable approle

# Create role
vault write auth/approle/role/app-role \
    token_policies="app-policy" \
    token_ttl=1h \
    token_max_ttl=4h

# Get credentials
vault read auth/approle/role/app-role/role-id
vault write -f auth/approle/role/app-role/secret-id
```

### Kubernetes Auth (for K8s pods)

```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure
vault write auth/kubernetes/config \
    kubernetes_host="https://kubernetes.default.svc:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token

# Create role
vault write auth/kubernetes/role/app-role \
    bound_service_account_names=app \
    bound_service_account_namespaces=default \
    policies=app-policy \
    ttl=1h
```

## Encryption as a Service

```bash
# Enable transit engine
vault secrets enable transit

# Create encryption key
vault write -f transit/keys/app-key

# Encrypt data
vault write transit/encrypt/app-key \
    plaintext=$(echo "secret data" | base64)

# Decrypt data
vault write transit/decrypt/app-key \
    ciphertext="vault:v1:..."
```

## Monitoring & Audit

### Enable Audit Log

```bash
vault audit enable file file_path=/vault/logs/audit.log
```

### Metrics (Prometheus)

```bash
# Vault exposes metrics on /v1/sys/metrics
curl http://localhost:8200/v1/sys/metrics
```

## Production Deployment

### High Availability Setup

```hcl
# vault-config.hcl
storage "consul" {
  address = "consul:8500"
  path    = "vault/"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 0
  tls_cert_file = "/vault/tls/cert.pem"
  tls_key_file  = "/vault/tls/key.pem"
}

api_addr = "https://vault.example.com:8200"
cluster_addr = "https://vault.example.com:8201"
ui = true
```

### Auto-Unseal with Cloud KMS

```hcl
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "arn:aws:kms:us-east-1:..."
}
```

## References

- [Vault Documentation](https://www.vaultproject.io/docs)
- [Kubernetes Integration](https://www.vaultproject.io/docs/platform/k8s)
- [Best Practices](https://learn.hashicorp.com/collections/vault/recommended-patterns)
