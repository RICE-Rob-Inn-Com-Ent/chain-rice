#!/bin/bash

# Create a local Kubernetes cluster using kind
echo "Creating local Kubernetes cluster with kind..."

# Create the cluster
kind create cluster --name rice-dev-cluster

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Check cluster status
echo "Cluster status:"
kubectl cluster-info

# Show nodes
echo "Nodes:"
kubectl get nodes

echo "Kubernetes cluster is ready!"
