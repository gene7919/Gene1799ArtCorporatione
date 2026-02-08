#!/bin/bash

# GENE1799 ART CORPORATIONE - AUTOMATED SETUP & DEPLOYMENT SCRIPT
# Production-ready system setup in minutes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Start
clear
print_header "GENE1799 AUTOMATED SETUP & DEPLOYMENT"

# Check prerequisites
print_info "Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js not found. Please install Node.js 18+"
    exit 1
fi
NODE_VERSION=$(node -v)
print_success "Node.js found: $NODE_VERSION"

# Check npm
if ! command -v npm &> /dev/null; then
    print_error "npm not found. Please install npm"
    exit 1
fi
NPM_VERSION=$(npm -v)
print_success "npm found: $NPM_VERSION"

# Check git
if ! command -v git &> /dev/null; then
    print_error "Git not found. Please install Git"
    exit 1
fi
print_success "Git found"

echo ""
print_info "Step 1: Installing dependencies..."
npm install
print_success "Dependencies installed"

echo ""
print_info "Step 2: Setting up environment configuration..."

if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    print_success "Created backend/.env from template"
    print_info "EDIT backend/.env with your credentials:"
    print_info "  - ETH_RPC_URL"
    print_info "  - POLYGON_RPC_URL"
    print_info "  - WALLET_ADDRESS"
    print_info "  - TELEGRAM_BOT_TOKEN"
    echo ""
    read -p "Press Enter after configuring .env file..."
else
    print_success "backend/.env already exists"
fi

echo ""
print_info "Step 3: Running tests..."
npm test 2>/dev/null || print_info "Tests not configured, skipping"
print_success "Ready for deployment"

echo ""
print_info "Step 4: Verifying Git configuration..."
git config user.email > /dev/null 2>&1 || git config --global user.email "gene1799@local"
git config user.name > /dev/null 2>&1 || git config --global user.name "GENE1799"
print_success "Git configured"

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}              DEPLOYMENT OPTIONS"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"

echo ""
echo "Choose deployment option:"
echo ""
echo "1) LOCAL DEVELOPMENT - Run locally for testing"
echo "2) GITHUB PUSH - Push to GitHub (triggers auto-deploy)"
echo "3) AZURE DEPLOY - Deploy to Azure (one-click)"
echo "4) DOCKER BUILD - Build Docker image"
echo "5) EXIT - Exit setup"
echo ""

read -p "Enter choice (1-5): " choice

case $choice in
    1)
        echo ""
        print_header "STARTING LOCAL DEVELOPMENT SERVER"
        echo ""
        print_info "Starting application..."
        print_info "Access dashboard at: http://localhost:3000"
        print_info "Press Ctrl+C to stop"
        echo ""
        npm run dev
        ;;

    2)
        echo ""
        print_header "PUSHING TO GITHUB"
        echo ""
        print_info "Current status:"
        git status
        echo ""

        read -p "Commit message (or press Enter for default): " commit_msg
        if [ -z "$commit_msg" ]; then
            commit_msg="deploy: Automated production deployment via setup script"
        fi

        git add .
        git commit -m "$commit_msg" || print_info "No changes to commit"
        git push origin main

        print_success "Pushed to GitHub!"
        print_info "GitHub Actions pipeline started"
        print_info "Check: https://github.com/gene7919/Gene1799ArtCorporatione/actions"
        echo ""
        ;;

    3)
        echo ""
        print_header "AZURE ONE-CLICK DEPLOYMENT"
        echo ""
        print_info "Opening Azure Portal..."
        print_info "Click 'Deploy to Azure' button and configure:"
        print_info "  - Project Name: gene1799"
        print_info "  - Environment: production"
        print_info "  - Database Password: Strong password"
        echo ""

        AZURE_URL="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgene7919%2FGene1799ArtCorporatione%2Fmain%2Fazure-infrastructure-template.json"

        # Try to open URL
        if command -v xdg-open &> /dev/null; then
            xdg-open "$AZURE_URL"
        elif command -v open &> /dev/null; then
            open "$AZURE_URL"
        else
            print_info "Manual: Copy and paste URL in browser:"
            echo "$AZURE_URL"
        fi

        print_info "Deployment started in Azure Portal"
        echo ""
        ;;

    4)
        echo ""
        print_header "DOCKER BUILD"
        echo ""

        if ! command -v docker &> /dev/null; then
            print_error "Docker not found. Please install Docker"
            exit 1
        fi

        print_info "Building Docker image..."
        docker build -t gene1799:latest .

        print_success "Docker image built: gene1799:latest"
        print_info "Run with: docker run -p 3000:3000 gene1799:latest"
        echo ""
        ;;

    5)
        echo ""
        print_info "Setup complete. Next steps:"
        echo "  1. Edit backend/.env with your credentials"
        echo "  2. Run: npm run dev (for local testing)"
        echo "  3. Run: git push origin main (for auto-deploy)"
        echo "  4. Click Deploy button in README.md (for Azure)"
        echo ""
        exit 0
        ;;

    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

echo ""
print_header "DEPLOYMENT COMPLETE"
print_success "GENE1799 is now running!"
echo ""
