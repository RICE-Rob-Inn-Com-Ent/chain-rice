#!/bin/bash
# Chaos Mesh Installation Script

set -e

echo "🌪️  Installing Chaos Mesh..."

# Add Chaos Mesh Helm repository
echo "📦 Adding Helm repository..."
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

# Install Chaos Mesh
echo "🚀 Installing Chaos Mesh..."
helm install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace chaos-mesh \
  --create-namespace \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock \
  --set dashboard.create=true \
  --set dashboard.securityMode=false

echo "⏳ Waiting for Chaos Mesh to be ready..."
kubectl wait --for=condition=Ready pods --all -n chaos-mesh --timeout=300s

echo "✅ Chaos Mesh installed successfully!"

# Port forward to dashboard
echo ""
echo "🌐 Access Chaos Mesh Dashboard:"
echo "   kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333"
echo "   Then visit: http://localhost:2333"

echo ""
echo "📚 Quick Start:"
echo "   kubectl apply -f chaos-mesh.yaml"
echo "   kubectl get podchaos -n chaos-testing"
echo "   kubectl describe podchaos pod-failure-example -n chaos-testing"
