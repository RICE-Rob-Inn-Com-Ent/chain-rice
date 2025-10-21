# 🔄 Common DevOps Workflows

Complete guide for common DevOps workflows and operations.

## 📋 Table of Contents

- [Deployment Workflows](#deployment-workflows)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting Workflows](#troubleshooting-workflows)
- [Maintenance Workflows](#maintenance-workflows)
- [Emergency Procedures](#emergency-procedures)

---

## 🚀 Deployment Workflows

### Initial Setup

**First-time infrastructure setup:**

```bash
# 1. Setup environment
./scripts/setup.sh

# 2. Configure cloud credentials
aws configure  # or az login, gcloud auth login

# 3. Deploy infrastructure
./scripts/deploy-all.sh --env dev
```

### Regular Deployment

**Standard deployment workflow:**

```bash
# 1. Update code
git pull origin main

# 2. Build images
./scripts/ci/build.sh

# 3. Run tests
./scripts/ci/test.sh

# 4. Deploy to dev
./scripts/ci/deploy.sh

# 5. Verify deployment
./scripts/health-check.sh --env dev

# 6. Deploy to staging (if tests pass)
./scripts/ci/deploy.sh --env staging

# 7. Deploy to production (with approval)
./scripts/ci/deploy.sh --env prod
```

### Adding New Service

**Complete workflow for new service:**

```bash
# 1. Create service infrastructure
./scripts/add-project.sh --interactive

# Or non-interactive:
./scripts/add-project.sh \
  --name my-service \
  --type backend \
  --language go \
  --port 8080 \
  --database yes \
  --env dev,staging,prod

# 2. Review generated files
ls -la .dev/terraform/modules/my-service
ls -la .dev/k8s/charts/my-service

# 3. Update main Terraform config
# Add module to terraform/main.tf

# 4. Deploy infrastructure
cd .dev/terraform
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# 5. Deploy to Kubernetes
cd .dev/k8s
helm upgrade --install my-service charts/my-service -n dev

# 6. Configure ArgoCD (optional)
kubectl apply -f k8s/argocd/my-service-app.yaml
```

### Blue-Green Deployment

**Zero-downtime deployment:**

```bash
# 1. Deploy green version
export DEPLOYMENT_STRATEGY=blue-green
export SERVICE_NAME=backend
export VERSION=v2.0.0
export NAMESPACE=prod

./scripts/ci/deploy.sh

# 2. Test green version
kubectl port-forward deployment/backend-green 8080:8080 -n prod
curl http://localhost:8080/health

# 3. Switch traffic (done automatically)
# Service selector updated to green version

# 4. Monitor metrics
kubectl top pods -n prod
kubectl logs -f deployment/backend -n prod

# 5. Rollback if issues
./scripts/ci/rollback.sh
```

### Canary Deployment

**Gradual rollout:**

```bash
# 1. Deploy canary (10% traffic)
export DEPLOYMENT_STRATEGY=canary
export CANARY_PERCENTAGE=10
export SERVICE_NAME=backend
export VERSION=v2.0.0

./scripts/ci/deploy.sh

# 2. Monitor canary metrics
kubectl logs -f deployment/backend-canary -n prod

# 3. Increase canary traffic
kubectl scale deployment/backend-canary --replicas=3 -n prod

# 4. Promote canary
kubectl set image deployment/backend backend=rice-mono/backend:v2.0.0 -n prod

# 5. Remove canary
kubectl delete deployment/backend-canary -n prod
```

---

## ⏪ Rollback Procedures

### Quick Rollback

**Immediate rollback to previous version:**

```bash
# 1. Rollback deployment
export SERVICE_NAME=backend
export NAMESPACE=prod

./scripts/ci/rollback.sh

# 2. Verify rollback
kubectl rollout status deployment/$SERVICE_NAME -n $NAMESPACE
kubectl get pods -n $NAMESPACE

# 3. Check application health
./scripts/health-check.sh --env prod
```

### Rollback to Specific Version

**Rollback to known good version:**

```bash
# 1. View rollout history
kubectl rollout history deployment/backend -n prod

# 2. Rollback to revision 3
export SERVICE_NAME=backend
export NAMESPACE=prod
export REVISION=3

./scripts/ci/rollback.sh

# 3. Verify
kubectl describe deployment/backend -n prod | grep Image
```

### Database Rollback

**Rollback database changes:**

```bash
# 1. Connect to database
kubectl exec -it postgres-0 -n prod -- psql -U postgres

# 2. List backups
SELECT * FROM backups ORDER BY created_at DESC LIMIT 5;

# 3. Restore from backup
pg_restore -U postgres -d rice_db /backups/backup_20240115.dump

# 4. Verify data
SELECT COUNT(*) FROM users;
```

---

## 🔍 Troubleshooting Workflows

### Pod CrashLoopBackOff

**Debug and fix crashing pods:**

```bash
# 1. Check pod status
kubectl get pods -n dev

# 2. Describe pod
kubectl describe pod backend-xxx -n dev

# 3. Check logs
kubectl logs backend-xxx -n dev
kubectl logs backend-xxx -n dev --previous

# 4. Common fixes:

# Fix 1: Update resource limits
kubectl set resources deployment/backend \
  --limits=memory=1Gi,cpu=1000m \
  --requests=memory=512Mi,cpu=500m \
  -n dev

# Fix 2: Fix environment variables
kubectl set env deployment/backend \
  DATABASE_HOST=postgres-service \
  -n dev

# Fix 3: Update image
kubectl set image deployment/backend \
  backend=rice-mono/backend:fixed-version \
  -n dev
```

### ImagePullBackOff

**Fix image pull errors:**

```bash
# 1. Check pod events
kubectl describe pod backend-xxx -n dev

# 2. Verify image exists
docker pull rice-mono/backend:latest

# 3. Check image pull secrets
kubectl get secrets -n dev

# 4. Create/update secret
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=$DOCKER_USER \
  --docker-password=$DOCKER_PASS \
  -n dev

# 5. Update deployment
kubectl patch deployment backend \
  -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}}' \
  -n dev
```

### Service Not Accessible

**Debug service networking:**

```bash
# 1. Check service
kubectl get svc backend -n dev
kubectl describe svc backend -n dev

# 2. Check endpoints
kubectl get endpoints backend -n dev

# 3. Test from within cluster
kubectl run test --rm -it --image=busybox -- /bin/sh
wget -O- http://backend:8080/health

# 4. Check ingress
kubectl get ingress -n dev
kubectl describe ingress backend -n dev

# 5. Test DNS
kubectl run test --rm -it --image=busybox -- nslookup backend
```

### High Resource Usage

**Debug and fix resource issues:**

```bash
# 1. Check resource usage
kubectl top nodes
kubectl top pods -n prod --sort-by=memory

# 2. Identify resource hogs
kubectl describe node <node-name> | grep -A 5 "Allocated resources"

# 3. Scale down non-critical services
kubectl scale deployment/bot --replicas=1 -n prod

# 4. Update resource limits
kubectl set resources deployment/backend \
  --limits=cpu=500m,memory=512Mi \
  -n prod

# 5. Enable HPA
kubectl autoscale deployment/backend \
  --min=3 --max=10 \
  --cpu-percent=70 \
  -n prod
```

---

## 🛠️ Maintenance Workflows

### Update Kubernetes Cluster

**Upgrade cluster version:**

```bash
# 1. Backup everything
velero backup create pre-upgrade-backup

# 2. Drain nodes one by one
kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data

# 3. Upgrade control plane (EKS example)
eksctl upgrade cluster --name rice-mono-cluster --version 1.30

# 4. Upgrade node groups
eksctl upgrade nodegroup \
  --cluster=rice-mono-cluster \
  --name=ng-1 \
  --kubernetes-version=1.30

# 5. Uncordon nodes
kubectl uncordon node-1

# 6. Verify
kubectl get nodes
kubectl version
```

### Certificate Renewal

**Renew SSL certificates:**

```bash
# 1. Check certificate expiry
kubectl get certificates -A

# 2. Force renewal
kubectl delete certificate backend-tls -n prod

# 3. Cert-manager will auto-renew
kubectl get certificaterequest -n prod -w

# 4. Verify new certificate
kubectl describe certificate backend-tls -n prod
```

### Database Maintenance

**Database backup and maintenance:**

```bash
# 1. Create backup
kubectl exec -it postgres-0 -n prod -- \
  pg_dump -U postgres rice_db > backup_$(date +%Y%m%d).sql

# 2. Upload to S3
aws s3 cp backup_$(date +%Y%m%d).sql s3://rice-mono-backups/

# 3. Run VACUUM
kubectl exec -it postgres-0 -n prod -- \
  psql -U postgres -c "VACUUM ANALYZE;"

# 4. Check database size
kubectl exec -it postgres-0 -n prod -- \
  psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('rice_db'));"
```

### Log Rotation

**Manage and rotate logs:**

```bash
# 1. Check log sizes
kubectl exec -it backend-xxx -n prod -- du -sh /var/log

# 2. Archive old logs
kubectl exec -it backend-xxx -n prod -- \
  tar czf /tmp/logs_$(date +%Y%m%d).tar.gz /var/log/*.log

# 3. Upload to S3
kubectl cp backend-xxx:/tmp/logs_$(date +%Y%m%d).tar.gz ./logs.tar.gz -n prod
aws s3 cp logs.tar.gz s3://rice-mono-logs/

# 4. Clear old logs
kubectl exec -it backend-xxx -n prod -- \
  find /var/log -name "*.log" -mtime +30 -delete
```

---

## 🚨 Emergency Procedures

### Total Service Outage

**Emergency recovery procedure:**

```bash
# 1. Assess situation
./scripts/health-check.sh --env prod --verbose

# 2. Check recent changes
kubectl rollout history deployment/backend -n prod
git log --oneline -10

# 3. Immediate rollback
./scripts/ci/rollback.sh

# 4. Scale up replicas
kubectl scale deployment/backend --replicas=10 -n prod

# 5. Check external dependencies
curl -I https://api.external-service.com/health

# 6. Enable maintenance mode (if needed)
kubectl apply -f maintenance-mode.yaml

# 7. Notify stakeholders
# Send alerts via Slack/PagerDuty

# 8. Post-mortem
# Document incident, root cause, resolution
```

### Database Corruption

**Database emergency recovery:**

```bash
# 1. Stop all write operations
kubectl scale deployment/backend --replicas=0 -n prod

# 2. Create emergency backup
kubectl exec -it postgres-0 -n prod -- \
  pg_dumpall -U postgres > emergency_backup_$(date +%Y%m%d_%H%M%S).sql

# 3. Assess corruption
kubectl exec -it postgres-0 -n prod -- \
  psql -U postgres -c "SELECT * FROM pg_stat_database;"

# 4. Restore from last good backup
kubectl exec -it postgres-0 -n prod -- \
  psql -U postgres < last_good_backup.sql

# 5. Verify integrity
kubectl exec -it postgres-0 -n prod -- \
  psql -U postgres -c "SELECT COUNT(*) FROM users;"

# 6. Restart services
kubectl scale deployment/backend --replicas=5 -n prod
```

### Security Breach

**Security incident response:**

```bash
# 1. IMMEDIATE ACTIONS
# Isolate affected systems
kubectl scale deployment/compromised-service --replicas=0 -n prod

# Block malicious IPs
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-malicious-ips
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 1.2.3.4/32  # Malicious IP
EOF

# 2. INVESTIGATE
# Collect logs
kubectl logs -l app=backend --tail=10000 -n prod > incident_logs.txt

# Check for unauthorized access
kubectl get pods -A -o json | jq '.items[].spec.containers[].image'

# Audit RBAC
kubectl auth can-i --list --as=system:serviceaccount:default:suspicious-sa

# 3. REMEDIATE
# Rotate all secrets
kubectl delete secret --all -n prod
./scripts/rotate-secrets.sh

# Update all images
kubectl set image deployment/backend backend=rice-mono/backend:patched -n prod

# 4. DOCUMENT
# Create incident report
# Update security policies
```

---

## 📚 Additional Resources

- [Main DevOps README](../README.md)
- [Ansible Guide](ANSIBLE.md)
- [Kubernetes Guide](KUBERNETES.md)
- [Terraform Guide](TERRAFORM.md)

---

**For emergencies, contact the DevOps team immediately!**
