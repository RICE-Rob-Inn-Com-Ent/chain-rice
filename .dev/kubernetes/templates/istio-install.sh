#!/bin/bash
# Istio Service Mesh Installation

set -e

echo "🕸️  Installing Istio Service Mesh..."

# Download Istio
echo "📦 Downloading Istio..."
curl -L https://istio.io/downloadIstio | sh -

# Navigate to Istio directory
cd istio-* || exit 1
export PATH=$PWD/bin:$PATH

# Install Istio with default profile
echo "🚀 Installing Istio..."
istioctl install --set profile=default -y

# Enable sidecar injection
echo "💉 Enabling sidecar injection for default namespace..."
kubectl label namespace default istio-injection=enabled --overwrite

# Install addons (Prometheus, Grafana, Jaeger, Kiali)
echo "📊 Installing observability addons..."
kubectl apply -f samples/addons/prometheus.yaml
kubectl apply -f samples/addons/grafana.yaml
kubectl apply -f samples/addons/jaeger.yaml
kubectl apply -f samples/addons/kiali.yaml

# Wait for Istio to be ready
echo "⏳ Waiting for Istio to be ready..."
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s

echo "✅ Istio installed successfully!"

# Display status
echo ""
echo "📈 Istio Status:"
istioctl version

echo ""
echo "🌐 Access Dashboards:"
echo "   Kiali:      kubectl port-forward -n istio-system svc/kiali 20001:20001"
echo "   Grafana:    kubectl port-forward -n istio-system svc/grafana 3000:3000"
echo "   Jaeger:     kubectl port-forward -n istio-system svc/tracing 16686:16686"
echo "   Prometheus: kubectl port-forward -n istio-system svc/prometheus 9090:9090"

echo ""
echo "📚 Next steps:"
echo "   kubectl apply -f istio-install.yaml"
echo "   istioctl analyze"
echo "   kubectl get pods -n istio-system"
