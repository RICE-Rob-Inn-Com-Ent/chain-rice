{ pkgs }:

{
  packages = with pkgs; [
    # Protocol Buffers core
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    
    # Buf CLI and tools
    buf
    
    # Go protobuf tools (Cosmos ecosystem)
    # Note: Some tools need to be installed via Go modules
    go  # Required for protoc-gen-gocosmos and other Go-based generators
    
    # gRPC tools
    grpcurl
    grpcui
    grpc  # provides grpc_cpp_plugin for C++
    
    # Additional protobuf generators
    protoc-gen-grpc-gateway
    protoc-gen-openapiv2
    protoc-gen-grpc-java
    
    # JSON/YAML tools for buf configuration
    jq
    yq
    
    # Text processing tools
    gnused
    gnugrep
    
    # Development tools
    git
    curl
    
    # Documentation generation
    protoc-gen-doc
    
    # Validation tools
    protolint
    
    # File utilities
    tree
    fd
    ripgrep

    # C/C++ toolchain for generated code
    gcc
    clang
    cmake
    pkg-config
    protobufc  # protoc-c for C code generation (protobuf-c)

    # Java toolchain for generation and builds
    jdk21
    maven
    gradle

    # Python toolchain for generation
    python3
    python3Packages.pip
    python3Packages.grpcio-tools
    python3Packages.protobuf
    python3Packages.mypy-protobuf
  ];
  
  envVars = {
    # Protocol Buffers configuration
    PROTOC = "${pkgs.protobuf}/bin/protoc";
    
    # Buf configuration
    BUF_CACHE_DIR = "$HOME/.cache/buf";
    BUF_CONFIG_DIR = "$HOME/.config/buf";
    
    # ChainRice specific proto settings
    CHAINRICE_PROTO_ROOT = "$PWD/contracts/proto";
    PROTO_ROOT = "$PWD/contracts/proto";
    
    # Go protobuf settings
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
    GO111MODULE = "on";
    
    # Cosmos SDK proto settings
    COSMOS_PROTO_VERSION = "v1.0.0-beta.5";
    COSMOS_SDK_VERSION = "v0.50.1";
    
    # gRPC settings
    GRPC_GO_REQUIRE_HANDSHAKE = "off";
    
    # Output directories
    PROTO_GO_OUT = "$PWD/backend/go";
    PROTO_TS_OUT = "$PWD/frontend";
    PROTO_RUST_OUT = "$PWD/contracts/rust";
    PROTO_PY_OUT = "$PWD/backend/python";
    PROTO_JAVA_OUT = "$PWD/backend/java";
    PROTO_CPP_OUT = "$PWD/backend/cpp";
    
    # Buf registry
    BUF_REGISTRY = "buf.build";
    
    # Development settings
    BUF_LOG_LEVEL = "info";
    PROTOC_LOG_LEVEL = "info";
  };
  
  shellHook = ''
    echo "📋 Protocol Buffers with Buf ${pkgs.buf.version}"
    echo "   • Protoc ${pkgs.protobuf.version} compiler"
    echo "   • Buf for schema management"
    echo "   • Cosmos SDK proto support"
    echo "   • gRPC tools available (Go, Java, C++)"
    echo "   • Multi-language code generation: Go, Python, Java, C/C++"
    
    # Create necessary directories
    mkdir -p $BUF_CACHE_DIR
    mkdir -p $BUF_CONFIG_DIR
    mkdir -p $CHAINRICE_PROTO_ROOT
    mkdir -p $GOBIN
    
    # Ensure Go bin is in PATH for protoc-gen-* tools
    export PATH="$GOBIN:$PATH"
    # Ensure Java and Python are available for generators
    export JAVA_HOME="${pkgs.jdk21.home}"
    if command -v python3 >/dev/null 2>&1; then
      export PYTHON=$(which python3)
    fi
    
    # Install required Go-based protoc generators
    echo "🛠️  Installing Cosmos SDK protoc generators..."
    
    if ! command -v protoc-gen-gocosmos &> /dev/null; then
      echo "   Installing protoc-gen-gocosmos..."
      go install github.com/cosmos/gogoproto/protoc-gen-gocosmos@latest
    fi
    
    if ! command -v protoc-gen-grpc-gateway &> /dev/null; then
      echo "   Installing protoc-gen-grpc-gateway..."
      go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
    fi
    
    if ! command -v protoc-gen-openapiv2 &> /dev/null; then
      echo "   Installing protoc-gen-openapiv2..."
      go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
    fi
    
    echo "🛠️  Ensuring Python gRPC tools are ready..."
    # grpcio-tools already installed via nix; expose convenience alias
    alias pyprotoc='python3 -m grpc_tools.protoc'

    # Set up proto workspace
    if [ -d "contracts/proto" ]; then
      echo "📁 Proto workspace found in contracts/proto"
      
      # Initialize buf workspace if buf.yaml doesn't exist
      if [ ! -f "contracts/proto/buf.yaml" ]; then
        echo "🔧 Initializing Buf workspace..."
        cd contracts/proto
        buf mod init
        cd - > /dev/null
      fi
      
      # Copy configuration from stacks if needed
      if [ ! -f "contracts/proto/buf.gen.yaml" ] && [ -f "../../../../stacks/proto/packages/buf.gen.yaml" ]; then
        echo "📋 Copying Buf generation config from stacks..."
        cp ../../../../stacks/proto/packages/buf.gen.yaml contracts/proto/
      fi
      
      # Update buf dependencies
      if [ -f "contracts/proto/buf.yaml" ]; then
        echo "📦 Updating Buf dependencies..."
        cd contracts/proto
        buf mod update
        cd - > /dev/null
      fi
    else
      echo "📁 Creating proto workspace..."
      mkdir -p contracts/proto
      cd contracts/proto
      
      # Create basic buf.yaml with Cosmos dependencies
      cat > buf.yaml << EOF
version: v2
modules:
  - path: proto
deps:
  - buf.build/cosmos/cosmos-proto
  - buf.build/cosmos/cosmos-sdk
  - buf.build/cosmos/gogo-proto
  - buf.build/cosmos/ics23
  - buf.build/googleapis/googleapis
  - buf.build/protocolbuffers/wellknowntypes
  - buf.build/cosmos/ibc
lint:
  use:
    - STANDARD
  except:
    - COMMENT_FIELD
    - RPC_REQUEST_STANDARD_NAME
    - RPC_RESPONSE_STANDARD_NAME
    - SERVICE_SUFFIX
breaking:
  use:
    - FILE
  except:
    - EXTENSION_NO_DELETE
    - FIELD_SAME_DEFAULT
EOF
      
      # Create basic buf.gen.yaml for Go generation
      cat > buf.gen.yaml << EOF
version: v2
plugins:
  - local: ["go", "tool", "github.com/cosmos/gogoproto/protoc-gen-gocosmos"]
    out: ../../backend/go
    opt:
      - plugins=grpc
      - Mgoogle/protobuf/any.proto=github.com/cosmos/gogoproto/types/any
      - Mcosmos/orm/v1/orm.proto=cosmossdk.io/orm
      - Mcosmos/app/v1alpha1/module.proto=cosmossdk.io/api/cosmos/app/v1alpha1
  - local: ["go", "tool", "github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway"]
    out: ../../backend/go
    opt:
      - logtostderr=true
      - allow_colon_final_segments=true
  - local: ["go", "tool", "github.com/grpc-ecosystem/grpc-gateway/protoc-gen-openapiv2"]
    out: ../../backend/go
    opt:
      - logtostderr=true
EOF
      
      # Create basic proto directory structure
      mkdir -p proto/chainrice/tax/v1
      
      # Create a sample proto file
      cat > proto/chainrice/tax/v1/tax.proto << EOF
syntax = "proto3";

package chainrice.tax.v1;

import "google/api/annotations.proto";
import "cosmos/msg/v1/msg.proto";
import "amino/amino.proto";

option go_package = "github.com/chainrice/tax/v1";

// Tax calculation service
service TaxService {
  // Calculate tax for a given amount
  rpc CalculateTax(CalculateTaxRequest) returns (CalculateTaxResponse) {
    option (google.api.http) = {
      post: "/chainrice/tax/v1/calculate"
      body: "*"
    };
  }
}

// Request for tax calculation
message CalculateTaxRequest {
  option (cosmos.msg.v1.signer) = "authority";
  option (amino.name) = "chainrice/CalculateTaxRequest";
  
  string authority = 1;
  string amount = 2;
  string tax_rate = 3;
  string description = 4;
}

// Response for tax calculation
message CalculateTaxResponse {
  string gross_amount = 1;
  string net_amount = 2;
  string tax_amount = 3;
  string tax_rate = 4;
}
EOF
      
      buf mod init
      buf mod update
      cd - > /dev/null
    fi
    
    # Aliases for common Buf operations
    alias buf-lint='buf lint'
    alias buf-format='buf format'
    alias buf-generate='buf generate'
    alias buf-build='buf build'
    alias buf-breaking='buf breaking --against .git#branch=main'
    alias buf-push='buf push'
    alias buf-export='buf export'
    
    # ChainRice specific aliases
    alias chainrice-proto='cd contracts/proto'
    alias proto-gen='buf generate'
    alias proto-lint='buf lint'
    alias proto-format='buf format -w'
    alias proto-deps='buf mod update'
    alias proto-clean='buf mod prune'
    
    # Multi-language generation aliases
    alias proto-gen-go='buf generate --template buf.gen.yaml'
    alias proto-gen-py='pyprotoc -I contracts/proto --python_out=$PROTO_PY_OUT --grpc_python_out=$PROTO_PY_OUT $(find contracts/proto -name "*.proto" -type f)'
    alias proto-gen-java='protoc -I contracts/proto --java_out=$PROTO_JAVA_OUT --plugin=protoc-gen-grpc-java=$(which protoc-gen-grpc-java) --grpc-java_out=$PROTO_JAVA_OUT $(find contracts/proto -name "*.proto" -type f)'
    alias proto-gen-cpp='protoc -I contracts/proto --cpp_out=$PROTO_CPP_OUT --grpc_out=$PROTO_CPP_OUT --plugin=protoc-gen-grpc=$(which grpc_cpp_plugin) $(find contracts/proto -name "*.proto" -type f)'
    alias proto-gen-ts='buf generate --template buf.gen.ts.yaml'
    alias proto-gen-rust='buf generate --template buf.gen.rust.yaml'
    
    # Protoc direct usage aliases
    alias protoc-go='protoc --go_out=. --go-grpc_out=. --proto_path=.'
    alias protoc-gateway='protoc --grpc-gateway_out=. --proto_path=.'
    alias protoc-py='pyprotoc --proto_path=. --python_out=. --grpc_python_out=.'
    alias protoc-java='protoc --proto_path=. --java_out=. --plugin=protoc-gen-grpc-java=$(which protoc-gen-grpc-java) --grpc-java_out=.'
    alias protoc-cpp='protoc --proto_path=. --cpp_out=. --plugin=protoc-gen-grpc=$(which grpc_cpp_plugin) --grpc_out=.'
    
    echo ""
    echo "🚀 Protocol Buffers ready!"
    echo "   • Run 'chainrice-proto' to navigate to proto directory"
    echo "   • Run 'proto-gen' to generate code from proto files"
    echo "   • Run 'proto-lint' to validate proto files"
    echo "   • Run 'buf-deps' to update dependencies"
  '';
}
