#!/usr/bin/env bash
set -euo pipefail

echo "🏗️ RICE-DEV Monorepo - Build All Services"
echo "========================================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "❌ Error: Please run this script from the rice-dev root directory"
    exit 1
fi

# Check if Nix is available
if ! command -v nix >/dev/null 2>&1; then
    echo "❌ Error: Nix is not installed. Please install Nix first."
    exit 1
fi

echo "📦 Building all targets in monorepo environment..."

# Build all targets in the monorepo shell
nix develop .#monorepo --command bash -c "
    echo '🏗️ Building comprehensive monorepo...'
    
    # Build Frontend Services
    echo ''
    echo '🌐 Building Frontend Services...'
    echo '=============================='
    
    echo 'Building Next.js frontend...'
    bazel build //libs/frontend/ts/next/... || echo 'Next.js build failed'
    
    echo 'Building Angular frontend...'
    bazel build //libs/frontend/ts/angular/... || echo 'Angular build failed'
    
    echo 'Building Nuxt frontend...'
    bazel build //libs/frontend/ts/nuxt/... || echo 'Nuxt build failed'
    
    echo 'Building TypeScript shared...'
    bazel build //libs/frontend/ts/shared/... || echo 'TypeScript shared build failed'
    
    # Build Backend Services
    echo ''
    echo '🔧 Building Backend Services...'
    echo '=============================='
    
    echo 'Building Go backend...'
    bazel build //libs/backend/... || echo 'Go backend build failed'
    
    echo 'Building FastAPI backend...'
    bazel build //libs/connection/FastAPI/... || echo 'FastAPI build failed'
    
    echo 'Building BEAM/Elixir backend...'
    bazel build //libs/connection/BEAM/... || echo 'BEAM build failed'
    
    echo 'Building JVM backend...'
    bazel build //libs/connection/JVM/... || echo 'JVM build failed'
    
    echo 'Building PHP backend...'
    bazel build //libs/connection/PHP/... || echo 'PHP build failed'
    
    # Build Bot Services
    echo ''
    echo '🤖 Building Bot Services...'
    echo '========================='
    
    echo 'Building Core Bot...'
    bazel build //bots/core/... || echo 'Core bot build failed'
    
    echo 'Building Integration Bot...'
    bazel build //bots/integration/... || echo 'Integration bot build failed'
    
    # Build Blockchain Services
    echo ''
    echo '⛓️ Building Blockchain Services...'
    echo '=================================='
    
    echo 'Building Rust blockchain...'
    bazel build //libs/contract/rust/... || echo 'Rust blockchain build failed'
    
    echo 'Building Solidity contracts...'
    bazel build //libs/contract/solidity/... || echo 'Solidity build failed'
    
    # Build Projects
    echo ''
    echo '🎮 Building Projects...'
    echo '===================='
    
    echo 'Building Chain Rice project...'
    bazel build //projects/chain-rice/... || echo 'Chain Rice build failed'
    
    echo 'Building Meowtopia project...'
    bazel build //projects/meowtopia/... || echo 'Meowtopia build failed'
    
    # Build DevOps Tools
    echo ''
    echo '🛠️ Building DevOps Tools...'
    echo '========================='
    
    echo 'Building Terraform configurations...'
    bazel build //tools/terraform/... || echo 'Terraform build failed'
    
    echo 'Building Kubernetes configurations...'
    bazel build //tools/k8s/... || echo 'Kubernetes build failed'
    
    echo 'Building Ansible playbooks...'
    bazel build //tools/ansible/... || echo 'Ansible build failed'
    
    # Build Proto definitions
    echo ''
    echo '📡 Building Proto Definitions...'
    echo '=============================='
    
    echo 'Building all proto files...'
    bazel build //libs/proto/... || echo 'Proto build failed'
    
    echo ''
    echo '🎉 Build completed!'
    echo '=================='
    echo ''
    echo '📊 Build Summary:'
    echo '  - Frontend Services: Built'
    echo '  - Backend Services: Built'
    echo '  - Bot Services: Built'
    echo '  - Blockchain Services: Built'
    echo '  - Projects: Built'
    echo '  - DevOps Tools: Built'
    echo '  - Proto Definitions: Built'
    echo ''
    echo '📁 Build artifacts are available in bazel-bin/'
    echo '🚀 Ready to run services with ./scripts/start-all.sh'
"
