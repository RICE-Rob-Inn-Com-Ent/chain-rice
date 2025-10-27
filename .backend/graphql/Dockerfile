# GraphQL Gateway Service
# Minimal Go HTTP server for GraphQL endpoint

FROM golang:1.23-alpine

WORKDIR /app

RUN apk add --no-cache curl

# Create simple GraphQL health server
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
		fmt.Fprint(w, `{"status":"ok","service":"graphql"}`)
	})

	http.HandleFunc("/graphql", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, `{"data":{"status":"GraphQL endpoint placeholder"}}`)
	})

	fmt.Println("✅ GraphQL service listening on :4000")
	log.Fatal(http.ListenAndServe(":4000", nil))
}
EOF

RUN go build -o graphql-server server.go

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:4000/health || exit 1

CMD ["./graphql-server"]
