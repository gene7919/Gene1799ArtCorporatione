#!/bin/bash
# Gene1799 Pre-Deployment Checklist

set -e

echo "=================================="
echo "🚀 Gene1799 Pre-Deployment Check"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_requirement() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅${NC} $1 installed"
        return 0
    else
        echo -e "${RED}❌${NC} $1 NOT found - Please install it"
        return 1
    fi
}

# Requirements Check
echo "1. Checking Requirements..."
check_requirement "node"
check_requirement "npm"
check_requirement "python3"
check_requirement "git"

echo ""
echo "2. Checking Dependencies..."

# Frontend
echo "   Checking frontend dependencies..."
if grep -q "react" frontend/package.json; then
    echo -e "   ${GREEN}✅${NC} React configured"
else
    echo -e "   ${RED}❌${NC} React not found"
fi

# Backend
echo "   Checking backend dependencies..."
if grep -q "express" backend/package.json; then
    echo -e "   ${GREEN}✅${NC} Express configured"
else
    echo -e "   ${RED}❌${NC} Express not found"
fi

# AI Agent
echo "   Checking AI Agent..."
if [ -f "ai-agent/requirements.txt" ]; then
    echo -e "   ${GREEN}✅${NC} requirements.txt exists"
else
    echo -e "   ${RED}❌${NC} requirements.txt missing"
fi

echo ""
echo "3. Checking Configuration Files..."

files_to_check=(
    ".env:backend"
    ".env:frontend"
    ".env:ai-agent"
    "render.yaml"
    "docker-compose.yml"
    ".github/workflows/deploy.yml"
)

for file in "${files_to_check[@]}"; do
    IFS=':' read -r path location <<< "$file"
    if [ -f "$location/$path" ]; then
        echo -e "   ${GREEN}✅${NC} $location/$path"
    else
        echo -e "   ${YELLOW}⚠️${NC}  $location/$path not found (may need configuration)"
    fi
done

echo ""
echo "4. Checking Build Scripts..."

# Check package.json scripts
if grep -q '"build":' package.json; then
    echo -e "   ${GREEN}✅${NC} Build script configured"
else
    echo -e "   ${RED}❌${NC} Build script not configured"
fi

echo ""
echo "5. Testing Local Build..."

echo "   Building backend..."
npm -w backend run build 2>/dev/null && echo -e "   ${GREEN}✅${NC} Backend builds successfully" || echo -e "   ${RED}❌${NC} Backend build failed"

echo "   Building frontend..."
npm -w frontend run build 2>/dev/null && echo -e "   ${GREEN}✅${NC} Frontend builds successfully" || echo -e "   ${RED}❌${NC} Frontend build failed"

echo ""
echo "=================================="
echo "✅ Pre-deployment check complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Push changes to GitHub"
echo "2. Go to https://dashboard.render.com"
echo "3. Select 'New +' → 'Blueprint'"
echo "4. Choose your repository"
echo "5. Click 'Deploy Blueprint'"
echo ""
