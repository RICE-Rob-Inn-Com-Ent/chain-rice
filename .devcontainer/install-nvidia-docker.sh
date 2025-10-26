#!/bin/bash

# Install NVIDIA Container Toolkit for Docker GPU support

echo "🎮 Installing NVIDIA Container Toolkit..."
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  This script needs sudo privileges"
  echo "Run: sudo bash $0"
  exit 1
fi

# Check if NVIDIA GPU exists
if ! command -v nvidia-smi &>/dev/null; then
  echo "❌ NVIDIA GPU not detected. Install NVIDIA drivers first!"
  exit 1
fi

echo "✅ NVIDIA GPU detected:"
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
echo ""

# Detect distribution
if [ -f /etc/arch-release ]; then
  DISTRO="arch"
elif [ -f /etc/debian_version ]; then
  DISTRO="debian"
elif [ -f /etc/fedora-release ]; then
  DISTRO="fedora"
else
  echo "❌ Unsupported distribution"
  exit 1
fi

echo "📦 Detected distribution: $DISTRO"
echo ""

# Install based on distro
if [ "$DISTRO" = "arch" ]; then
  echo "Installing via pacman..."
  pacman -S --needed --noconfirm nvidia-container-toolkit

elif [ "$DISTRO" = "debian" ]; then
  echo "Installing via apt..."
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  apt-get update
  apt-get install -y nvidia-container-toolkit

elif [ "$DISTRO" = "fedora" ]; then
  echo "Installing via dnf..."
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo |
    tee /etc/yum.repos.d/nvidia-container-toolkit.repo
  dnf install -y nvidia-container-toolkit
fi

echo ""
echo "🔧 Configuring Docker..."

# Configure Docker to use nvidia runtime
nvidia-ctk runtime configure --runtime=docker

echo ""
echo "🔄 Restarting Docker..."
systemctl restart docker

echo ""
echo "✅ Testing GPU access in Docker..."
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi

echo ""
echo "✅ Installation complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Restart your terminal"
echo "   2. Go to .devcontainer: cd /home/mrDinkelman/rice-mono/.devcontainer"
echo "   3. Run: docker-compose up -d thoth"
echo ""
echo "🎮 Thoth will now use NVIDIA GPU automatically!"
