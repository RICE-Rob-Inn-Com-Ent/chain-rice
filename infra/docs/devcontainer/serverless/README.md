# Serverless Functions with Knative

## Overview

Knative is a Kubernetes-based platform for deploying and managing serverless workloads. It provides auto-scaling
(including scale-to-zero), event-driven architecture, and simplified deployment.

## Features

- ✅ **Scale to Zero** - Automatically scale down to 0 when not in use
- ✅ **Auto-scaling** - Scale based on traffic
- ✅ **Event-Driven** - Trigger functions from events
- ✅ **Multi-Language** - Support for any container
- ✅ **Cloud-Native** - Built on Kubernetes

## Architecture

```
┌──────────────────────────────────────────┐
│         Knative Serving Layer            │
│  ┌────────────────────────────────────┐  │
│  │  Auto-scaler + Traffic Routing     │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌──────────────┐        ┌──────────────┐
│  Function 1  │        │  Function 2  │
│  (Replicas)  │        │  (Replicas)  │
└──────────────┘        └──────────────┘
```

## Structure

```
serverless/
├── functions/          # Serverless functions
│   ├── hello/         # Example function
│   ├── api/           # API functions
│   └── processors/    # Event processors
├── knative/           # Knative manifests
│   ├── services/      # Knative Services
│   └── eventing/      # Event sources
└── scripts/           # Deployment scripts
```

## Quick Start

### 1. Install Knative

```bash
# Install Knative Serving
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.15.0/serving-crds.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.15.0/serving-core.yaml

# Install networking layer (Kourier)
kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.15.0/kourier.yaml

# Configure Knative to use Kourier
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
```

### 2. Deploy a Function

```bash
# Deploy using kubectl
kubectl apply -f knative/services/hello-service.yaml

# Or use Knative CLI (kn)
kn service create hello \
  --image ghcr.io/knative/helloworld-go:latest \
  --port 8080 \
  --env TARGET=World
```

### 3. Invoke Function

```bash
# Get the URL
export SERVICE_URL=$(kubectl get ksvc hello -o jsonpath='{.status.url}')

# Call the function
curl $SERVICE_URL
```

## Example Functions

### Python Function

```python
# functions/hello/app.py
from flask import Flask, request
import os

app = Flask(__name__)

@app.route('/')
def hello():
    target = os.environ.get('TARGET', 'World')
    return f'Hello {target}!\n'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
```

### Go Function

```go
// functions/api/main.go
package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
)

func handler(w http.ResponseWriter, r *http.Request) {
    target := os.Getenv("TARGET")
    if target == "" {
        target = "World"
    }
    fmt.Fprintf(w, "Hello %s!\n", target)
}

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    http.HandleFunc("/", handler)
    log.Printf("Listening on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
```

## Knative Service Manifest

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello-function
  namespace: default
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/min-scale: "0"
        autoscaling.knative.dev/max-scale: "10"
        autoscaling.knative.dev/target: "10"
    spec:
      containers:
        - image: your-registry/hello-function:latest
          ports:
            - containerPort: 8080
          env:
            - name: TARGET
              value: "Knative"
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "200m"
```

## Event-Driven Functions

### Event Source (Kafka)

```yaml
apiVersion: sources.knative.dev/v1beta1
kind: KafkaSource
metadata:
  name: kafka-source
spec:
  consumerGroup: knative-group
  bootstrapServers:
    - kafka.default.svc:9092
  topics:
    - orders
  sink:
    ref:
      apiVersion: serving.knative.dev/v1
      kind: Service
      name: order-processor
```

## Auto-scaling Configuration

```yaml
annotations:
  # Minimum replicas (0 for scale-to-zero)
  autoscaling.knative.dev/min-scale: "0"

  # Maximum replicas
  autoscaling.knative.dev/max-scale: "100"

  # Target concurrent requests per pod
  autoscaling.knative.dev/target: "10"

  # Scale-down window
  autoscaling.knative.dev/scale-down-delay: "15m"

  # Metric type (concurrency or rps)
  autoscaling.knative.dev/metric: "concurrency"
```

## Technologies

- **Knative Serving** - Serverless runtime
- **Knative Eventing** - Event delivery
- **Kourier** - Lightweight ingress
- **Kubernetes** - Orchestration platform

## Monitoring

```bash
# View service status
kn service list

# Describe service
kn service describe hello

# View logs
kubectl logs -l serving.knative.dev/service=hello -c user-container

# View metrics
kubectl get podmetrics -n default
```

## References

- [Knative Documentation](https://knative.dev/docs/)
- [Knative Functions](https://knative.dev/docs/functions/)
- [Auto-scaling Guide](https://knative.dev/docs/serving/autoscaling/)
