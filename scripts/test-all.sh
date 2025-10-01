#!/usr/bin/env bash
set -euo pipefail

echo "🧪 RICE-DEV Monorepo - Test All Services"
echo "======================================="

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

echo "📦 Building all targets first..."
nix develop .#monorepo --command bazel build //...

echo ""
echo "🧪 Running all tests..."

# Run all tests in the monorepo shell
nix develop .#monorepo --command bash -c "
    echo 'Running comprehensive test suite...'
    
    # Test Frontend Services
    echo ''
    echo '🌐 Testing Frontend Services...'
    echo '=============================='
    
    echo 'Testing Next.js frontend...'
    bazel test //libs/frontend/ts/next/... || echo 'Next.js tests failed'
    
    echo 'Testing Angular frontend...'
    bazel test //libs/frontend/ts/angular/... || echo 'Angular tests failed'
    
    echo 'Testing Nuxt frontend...'
    bazel test //libs/frontend/ts/nuxt/... || echo 'Nuxt tests failed'
    
    echo 'Testing TypeScript shared...'
    bazel test //libs/frontend/ts/shared/... || echo 'TypeScript shared tests failed'
    
    # Test Backend Services
    echo ''
    echo '🔧 Testing Backend Services...'
    echo '=============================='
    
    echo 'Testing Go backend...'
    bazel test //libs/backend/... || echo 'Go backend tests failed'
    
    echo 'Testing FastAPI backend...'
    bazel test //libs/connection/FastAPI/... || echo 'FastAPI tests failed'
    
    echo 'Testing BEAM/Elixir backend...'
    bazel test //libs/connection/BEAM/... || echo 'BEAM tests failed'
    
    echo 'Testing JVM backend...'
    bazel test //libs/connection/JVM/... || echo 'JVM tests failed'
    
    echo 'Testing PHP backend...'
    bazel test //libs/connection/PHP/... || echo 'PHP tests failed'
    
    # Test Bot Services
    echo ''
    echo '🤖 Testing Bot Services...'
    echo '========================='
    
    echo 'Testing Core Bot...'
    bazel test //bots/core/... || echo 'Core bot tests failed'
    
    echo 'Testing Integration Bot...'
    bazel test //bots/integration/... || echo 'Integration bot tests failed'
    
    # Test Blockchain Services
    echo ''
    echo '⛓️ Testing Blockchain Services...'
    echo '==============================='
    
    echo 'Testing Rust blockchain...'
    bazel test //libs/contract/rust/... || echo 'Rust blockchain tests failed'
    
    echo 'Testing Solidity contracts...'
    bazel test //libs/contract/solidity/... || echo 'Solidity tests failed'
    
    # Test Projects
    echo ''
    echo '🎮 Testing Projects...'
    echo '===================='
    
    echo 'Testing Chain Rice project...'
    bazel test //projects/chain-rice/... || echo 'Chain Rice tests failed'
    
    echo 'Testing Meowtopia project...'
    bazel test //projects/meowtopia/... || echo 'Meowtopia tests failed'
    
    # Test DevOps Tools
    echo ''
    echo '🛠️ Testing DevOps Tools...'
    echo '========================='
    
    echo 'Testing Terraform configurations...'
    bazel test //tools/terraform/... || echo 'Terraform tests failed'
    
    echo 'Testing Kubernetes configurations...'
    bazel test //tools/k8s/... || echo 'Kubernetes tests failed'
    
    echo 'Testing Ansible playbooks...'
    bazel test //tools/ansible/... || echo 'Ansible tests failed'
    
    echo ''
    echo '🎉 Test suite completed!'
    echo '======================'
    echo ''
    echo '📊 Test Summary:'
    echo '  - Frontend Services: Tested'
    echo '  - Backend Services: Tested'
    echo '  - Bot Services: Tested'
    echo '  - Blockchain Services: Tested'
    echo '  - Projects: Tested'
    echo '  - DevOps Tools: Tested'
    echo ''
    echo '📝 Check individual test outputs above for detailed results.'
"
