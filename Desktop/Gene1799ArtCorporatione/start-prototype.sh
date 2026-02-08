#!/bin/bash

# GENE1799 LOCAL PROTOTYPE LAUNCHER - Linux/Mac
# Avvia il sistema completo come prototipo locale

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   GENE1799 LOCAL PROTOTYPE LAUNCHER                   ║${NC}"
echo -e "${CYAN}║   Production-ready system on localhost                ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[*] Checking prerequisites...${NC}"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}[ERROR] Node.js not found${NC}"
    exit 1
fi
NODE_VERSION=$(node --version)
echo -e "${GREEN}[OK] Node.js $NODE_VERSION${NC}"

# Check npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}[ERROR] npm not found${NC}"
    exit 1
fi
NPM_VERSION=$(npm --version)
echo -e "${GREEN}[OK] npm $NPM_VERSION${NC}"

# Check directories
for dir in "backend/src" "frontend" "telegram-bot"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}[OK] $dir found${NC}"
    else
        echo -e "${RED}[ERROR] $dir not found${NC}"
        exit 1
    fi
done

# Setup environment
echo ""
echo -e "${YELLOW}[*] Setting up environment...${NC}"

if [ ! -f "backend/.env" ]; then
    if [ -f "backend/.env.example" ]; then
        cp backend/.env.example backend/.env
        echo -e "${YELLOW}[!] Created backend/.env from template${NC}"
        echo -e "${YELLOW}[!] Please configure backend/.env with your credentials${NC}"
    fi
fi

echo -e "${GREEN}[OK] Environment configured${NC}"

# Install dependencies
echo ""
echo -e "${YELLOW}[*] Installing dependencies...${NC}"
npm install > /dev/null 2>&1 || {
    echo -e "${RED}[ERROR] Failed to install dependencies${NC}"
    exit 1
}
echo -e "${GREEN}[OK] Dependencies installed${NC}"

# Launch prototype
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              LAUNCHING PROTOTYPE SYSTEM                ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}[INFO] Starting GENE1799 Local Prototype...${NC}"
echo ""
echo -e "${CYAN}Services starting:${NC}"
echo -e "  ${GREEN}📊 Dashboard       → http://localhost:3000${NC}"
echo -e "  ${GREEN}🌐 Web3 dApps      → http://localhost:3000/web3-dapps-dashboard.html${NC}"
echo -e "  ${GREEN}🔌 Backend API     → http://localhost:3001${NC}"
echo -e "  ${GREEN}🤖 Telegram Bot    → Polling active${NC}"
echo ""

# Run prototype launcher
node start-prototype.js
