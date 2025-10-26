#!/bin/bash
# Initialize all Egyptian Gods - Pre-cache all models

set -e

# ANSI color codes for beautiful terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
AMBER='\033[38;5;214m'
GOLD='\033[38;5;220m'
NC='\033[0m' # No Color

echo -e "${GOLD}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║                                                   ║${NC}"
echo -e "${GOLD}║   ${AMBER}🏛️  EGYPTIAN GODS AI PANTHEON INIT${GOLD}  🏛️       ║${NC}"
echo -e "${GOLD}║                                                   ║${NC}"
echo -e "${GOLD}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
  echo -e "${RED}❌ Docker not found! Please install Docker.${NC}"
  exit 1
fi

echo -e "${CYAN}📦 Starting all god containers...${NC}"
echo ""

# Start all containers
docker-compose up -d

echo ""
echo -e "${PURPLE}⏳ Waiting for containers to be ready...${NC}"
sleep 5

# Array of gods with their details
declare -A GODS
GODS["thoth"]="📜 Thoth|mistral:latest|11434|${CYAN}"
GODS["ra"]="☀️ Ra|llama3.3:latest|11435|${AMBER}"
GODS["anubis"]="🐺 Anubis|deepseek-coder:6.7b|11436|${WHITE}"
GODS["isis"]="✨ Isis|phi4:latest|11437|${PURPLE}"
GODS["horus"]="🦅 Horus|gemma2:9b|11438|${BLUE}"

# Pull models for each god
for god in "${!GODS[@]}"; do
  IFS='|' read -r icon model port color <<<"${GODS[$god]}"

  echo ""
  echo -e "${color}════════════════════════════════════════${NC}"
  echo -e "${color}${icon} Initializing ${god^}${NC}"
  echo -e "${color}Model: ${model}${NC}"
  echo -e "${color}Port:  ${port}${NC}"
  echo -e "${color}════════════════════════════════════════${NC}"

  # Check if container is running
  if docker ps | grep -q "ai-god-${god}"; then
    echo -e "${GREEN}✓ Container is running${NC}"

    # Pull the model
    echo -e "${YELLOW}📥 Downloading model (this may take a while)...${NC}"
    docker exec "ai-god-${god}" ollama pull "${model}" 2>&1 | while IFS= read -r line; do
      if [[ $line == *"pulling"* ]]; then
        echo -e "${BLUE}  ${line}${NC}"
      elif [[ $line == *"success"* ]] || [[ $line == *"complete"* ]]; then
        echo -e "${GREEN}  ✓ ${line}${NC}"
      elif [[ $line == *"error"* ]] || [[ $line == *"failed"* ]]; then
        echo -e "${RED}  ✗ ${line}${NC}"
      elif [[ $line == *"%"* ]]; then
        echo -e "${CYAN}  ${line}${NC}"
      else
        echo -e "  ${line}"
      fi
    done

    echo -e "${GREEN}✅ ${icon} ${god^} is ready!${NC}"
  else
    echo -e "${RED}✗ Container not running${NC}"
    echo -e "${YELLOW}  Try: docker-compose up -d ${god}${NC}"
  fi
done

echo ""
echo -e "${GOLD}════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Pantheon Initialization Complete!${NC}"
echo -e "${GOLD}════════════════════════════════════════${NC}"
echo ""

# Show status
echo -e "${CYAN}📊 Status of the Gods:${NC}"
echo ""

for god in "${!GODS[@]}"; do
  IFS='|' read -r icon model port color <<<"${GODS[$god]}"

  if docker ps | grep -q "ai-god-${god}"; then
    status="${GREEN}⚡ ACTIVE${NC}"
  else
    status="${RED}🌙 SLEEPING${NC}"
  fi

  echo -e "${color}  ${icon} ${god^:12}${NC} - ${status} - Port: ${port}"
done

echo ""
echo -e "${PURPLE}🌐 Web Interface:${NC}  ${CYAN}http://localhost:3000${NC}"
echo -e "${PURPLE}🔧 Cache Manager:${NC}  ${CYAN}http://localhost:9090${NC}"
echo ""
echo -e "${GOLD}𓂀 May the gods guide your AI journey! 𓁹${NC}"
echo ""
