# GraphQL Router Configuration

## Usage

Router configuration uses environment variables. Generate config from template:

```bash
export PROJECT_SLUG=code-rice
export GRAPHQL_SERVICE_NAME=${PROJECT_SLUG}-graphql-router
export GRAPHQL_CORS_ORIGINS=http://localhost:3000,http://localhost:3001
export AUTH_SERVICE_URL=http://localhost:4001

# Use envsubst to generate router.yaml
envsubst < router/router.yaml.template > router/router.yaml
```

## Required Environment Variables

- `PROJECT_SLUG` - Project identifier
- `GRAPHQL_SERVICE_NAME` - Service name for telemetry (defaults to ${PROJECT_SLUG}-graphql-router)
- `GRAPHQL_CORS_ORIGINS` - Comma-separated CORS origins
- `AUTH_SERVICE_URL` - Authentication service URL
