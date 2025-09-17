{ pkgs }:

{
  packages = with pkgs; [
    # Go toolchain
    go
    gopls
    go-tools
    gotools
    goimports
    gomod2nix
    gofumpt
    
    # Go development tools
    delve  # debugger
    golangci-lint
    staticcheck
    govulncheck
    gosec
    
    # Cosmos SDK specific tools
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    protoc-gen-grpc-gateway
    buf
    
    # Database tools for Go
    sqlite
    sqlite-interactive
    sqlc
    oapi-codegen
    go-task
    
    # Build tools
    gnumake
    gcc
    
    # Networking tools for blockchain development
    grpcurl
    
    # Testing tools
    gotestsum
  ];
  
  envVars = {
    # Go configuration
    GO111MODULE = "on";
    GOPROXY = "https://proxy.golang.org,direct";
    GOSUMDB = "sum.golang.org";
    CGO_ENABLED = "1";  # Required for SQLite
    
    # Cosmos SDK specific
    COSMOS_BUILD_OPTIONS = "nostrip";
    
    # ChainRice Go modules
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
    
    # Database
    CGO_CFLAGS = "-DSQLITE_ENABLE_FTS5";
    
    # Build optimization
    GOMAXPROCS = "4";
  };
  
  shellHook = ''
    echo "🐹 Go ${pkgs.go.version} configured for Cosmos SDK development"
    echo "   • SQLite support enabled"
    echo "   • Protocol Buffers ready"
    echo "   • Blockchain tools available"
    echo "   • Extras: sqlc, oapi-codegen, buf, gofumpt, gosec"
    
    # Ensure Go bin is in PATH
    export PATH="$GOBIN:$PATH"
    
    # Create Go workspace if it doesn't exist
    mkdir -p $GOPATH/{bin,src,pkg}
    
    # Install additional Go tools if needed
    if ! command -v goimports &> /dev/null; then
      echo "Installing goimports..."
      go install golang.org/x/tools/cmd/goimports@latest
    fi
    
    # Cosmos SDK tools
    if ! command -v protoc-gen-gocosmos &> /dev/null; then
      echo "Installing Cosmos SDK protobuf tools..."
      go install github.com/cosmos/gogoproto/protoc-gen-gocosmos@latest
    fi

    # Formatting and linters
    if ! command -v gofumpt &> /dev/null; then
      echo "Installing gofumpt..."
      go install mvdan.cc/gofumpt@latest
    fi

    # Code generation and utilities
    if ! command -v mockgen &> /dev/null; then
      echo "Installing mockgen..."
      go install github.com/golang/mock/mockgen@latest
    fi
    if ! command -v swag &> /dev/null; then
      echo "Installing swag (OpenAPI generator)..."
      go install github.com/swaggo/swag/cmd/swag@latest
    fi
    if ! command -v wire &> /dev/null; then
      echo "Installing google/wire..."
      go install github.com/google/wire/cmd/wire@latest
    fi
    if ! command -v benchstat &> /dev/null; then
      echo "Installing benchstat..."
      go install golang.org/x/perf/cmd/benchstat@latest
    fi
    if ! command -v air &> /dev/null; then
      echo "Installing air (live reload)..."
      go install github.com/cosmtrek/air@latest
    fi
    if ! command -v modd &> /dev/null; then
      echo "Installing modd (file watcher)..."
      go install github.com/cortesi/modd/cmd/modd@latest
    fi
    if ! command -v protoc-gen-validate &> /dev/null; then
      echo "Installing protoc-gen-validate..."
      go install github.com/envoyproxy/protoc-gen-validate@latest
    fi
    if ! command -v protoc-gen-connect-go &> /dev/null; then
      echo "Installing protoc-gen-connect-go..."
      go install github.com/bufbuild/connect-go/cmd/protoc-gen-connect-go@latest
    fi
    if ! command -v protoc-gen-openapiv2 &> /dev/null; then
      echo "Installing protoc-gen-openapiv2..."
      go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
    fi

    # Security tools
    if ! command -v gosec &> /dev/null; then
      echo "Installing gosec..."
      go install github.com/securego/gosec/v2/cmd/gosec@latest
    fi

    # Database/codegen helpers
    if command -v sqlc &> /dev/null && [ -f "sqlc.yaml" ]; then
      echo "Running sqlc generate..."
      sqlc generate || true
    fi
    
    # Helpful aliases
    alias gb='go build ./...'
    alias gt='go test ./...'
    alias gtr='go test -race ./...'
    alias gtc='go test -cover ./...'
    alias gcover='go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out'
    alias gfmt='gofumpt -l -w . && goimports -w .'
    alias gvet='go vet ./...'
    alias gci='golangci-lint run'
  '';
}
