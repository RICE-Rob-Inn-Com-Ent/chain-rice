# Data Service - DDD + CQRS Backend
# Minimal Go HTTP server

FROM golang:1.23-alpine

WORKDIR /app

RUN apk add --no-cache curl

# Create simple health check server
COPY <<'EOF' /app/server.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, `{"status":"ok","service":"data"}`)
	})

	fmt.Println("✅ Data service listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
EOF

RUN go build -o data-server server.go

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8080/health || exit 1

CMD ["./data-server"]
