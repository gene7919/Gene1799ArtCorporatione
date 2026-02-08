# ⚡ QUICK START - GENE1799 AUTOMATED DEPLOYMENT

**Time to Production: 5-15 minutes**

---

## 🚀 CHOOSE YOUR PATH

### OPTION 1: Windows PowerShell (Recommended for Windows Users)

```powershell
# Run the setup wizard
.\setup-and-deploy.ps1
```

Then choose from menu:
- **1** → Run locally for testing
- **2** → Deploy to GitHub (auto-deploy to Render)
- **3** → Deploy to Azure (one-click)
- **4** → Verify all systems
- **5** → Exit

---

### OPTION 2: Windows Command Prompt

```cmd
# Run the batch script
setup-and-deploy.bat
```

Then select deployment option from menu.

---

### OPTION 3: Linux/Mac (Bash)

```bash
# Make script executable
chmod +x setup-and-deploy.sh

# Run the setup wizard
./setup-and-deploy.sh
```

Then choose from menu options.

---

### OPTION 4: Manual Setup (No Script)

```bash
# 1. Install dependencies
npm install

# 2. Configure environment
cp backend/.env.example backend/.env
# Edit backend/.env with your RPC URLs and credentials

# 3. Run locally
npm run dev

# 4. Or push to GitHub
git push origin main
```

---

## 📋 WHAT YOU NEED BEFORE STARTING

### For Local Development
- ✅ Node.js 18+ (check: `node --version`)
- ✅ npm 9+ (check: `npm --version`)
- ✅ Git (check: `git --version`)

### For GitHub Auto-Deploy
- ✅ GitHub account
- ✅ 9 GitHub Secrets configured (see below)

### For Azure Deployment
- ✅ Azure subscription
- ✅ Azure CLI installed (optional)

---

## 🔑 CONFIGURE GITHUB SECRETS (9 Required)

If using GitHub auto-deploy, add these secrets:

1. Go to: **GitHub → Settings → Secrets and variables → Actions**
2. Click **New repository secret** and add:

```
TELEGRAM_BOT_TOKEN          → From @BotFather on Telegram
TELEGRAM_CHANNEL_ID         → Your channel/chat ID
TELEGRAM_ADMIN_ID           → Your user ID
RENDER_API_KEY              → From https://render.com
AZURE_SUBSCRIPTION_ID       → Your Azure subscription
AZURE_CLIENT_ID             → Azure app registration ID
AZURE_CLIENT_SECRET         → Azure app secret
AZURE_TENANT_ID             → Your Azure tenant ID
ENCRYPTION_KEY              → Generate: openssl rand -hex 32
```

---

## 📝 CONFIGURE ENVIRONMENT FILE

Edit `backend/.env`:

```bash
# RPC Endpoints (free options available)
ETH_RPC_URL=https://eth.llamarpc.com
POLYGON_RPC_URL=https://polygon-rpc.com
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
OPTIMISM_RPC_URL=https://mainnet.optimism.io
BASE_RPC_URL=https://mainnet.base.org

# Your Wallet
WALLET_ADDRESS=0x...your_address...
PRIVATE_KEY=0x...your_private_key... (NEVER commit this!)

# API Keys
OPENSEA_API_KEY=your_key
COINGECKO_API_KEY=your_key  # Optional

# Telegram
TELEGRAM_BOT_TOKEN=your_token
TELEGRAM_CHANNEL_ID=your_channel_id
TELEGRAM_ADMIN_ID=your_user_id
```

⚠️ **NEVER commit private keys! Use .env, not code!**

---

## 🎯 TYPICAL WORKFLOWS

### WORKFLOW 1: Local Testing (5 minutes)
```
1. Run: .\setup-and-deploy.ps1 (or .sh or .bat)
2. Select: Option 1 (LOCAL DEVELOPMENT)
3. Access: http://localhost:3000
4. Test: Try Web3 operations
5. Stop: Ctrl+C
```

**Result**: Test everything locally before deploy

### WORKFLOW 2: Auto-Deploy to Render (5 minutes)
```
1. Configure: 9 GitHub Secrets
2. Run: .\setup-and-deploy.ps1
3. Select: Option 2 (GITHUB PUSH)
4. Confirm: Push commits
5. Monitor: GitHub Actions tab
6. Access: Render dashboard
```

**Result**: Auto-deployed to Render.com in <5 minutes

### WORKFLOW 3: Azure Deployment (10 minutes)
```
1. Run: .\setup-and-deploy.ps1
2. Select: Option 3 (AZURE DEPLOY)
3. Configure: Azure Portal form
4. Submit: Click "Create"
5. Monitor: Azure dashboard
6. Access: Your Azure app URL
```

**Result**: Full cloud infrastructure in Azure

### WORKFLOW 4: Docker Deployment (10 minutes)
```
1. Install: Docker Desktop
2. Run: .\setup-and-deploy.ps1
3. Select: Not in interactive mode
4. BuildDocker: docker build -t gene1799 .
5. Run: docker run -p 3000:3000 gene1799
6. Access: http://localhost:3000
```

**Result**: Containerized for any platform

---

## ✅ HOW TO VERIFY IT'S WORKING

### Test 1: Web3 Integration
```bash
# Check Web3 module loads
node -e "const w = require('./backend/src/web3-dapps-integration'); console.log('✓ Web3 loaded');"
```

### Test 2: Dashboard Access
```bash
# Open in browser
open frontend/web3-dapps-dashboard.html
# Or: start frontend/web3-dapps-dashboard.html (Windows)
```

### Test 3: API Health
```bash
# If running local dev
curl http://localhost:3000/health
# Should return: { status: "ok" }
```

### Test 4: Git Status
```bash
# Check everything is committed
git status
# Should show: "On branch main, nothing to commit"
```

---

## 🚨 TROUBLESHOOTING

### "Node.js not found"
→ Install from: https://nodejs.org (18+ LTS)

### "npm: command not found"
→ Node.js not in PATH. Restart terminal.

### "Git not found"
→ Install from: https://git-scm.com

### ".env not found"
→ Run script again, it will create it from template

### "Permission denied" on script
→ Windows: Use PowerShell as Admin
→ Linux/Mac: chmod +x setup-and-deploy.sh

### "GitHub Actions failed"
→ Check: Settings → Secrets (are all 9 configured?)
→ Check: GitHub Actions tab for error logs

### "Azure deployment failed"
→ Check: Azure subscription is active
→ Check: Have enough quota/credits
→ Check: Region is correct (westeurope)

---

## 📊 DEPLOYMENT COMPARISON

| Feature | Local | Render | Azure | Docker |
|---------|-------|--------|-------|--------|
| Time | 5 min | 5 min | 15 min | 10 min |
| Cost | Free | Free($) | ~$160/mo | Varies |
| Scaling | None | Auto | 1-5 instances | Manual |
| Database | SQLite | PostgreSQL | PostgreSQL | Custom |
| Monitoring | None | Basic | Advanced | Custom |
| Best For | Development | Testing | Production | flexibility |

---

## 🔗 IMPORTANT LINKS

**After Deployment, Access:**
- 🌐 Application: https://your-domain.com
- 📊 Dashboard: https://your-domain.com/dashboard
- 🌐 Web3 dApps: https://your-domain.com/web3-dashboard.html
- 📈 Azure Portal: https://portal.azure.com
- 🐙 GitHub Repo: https://github.com/gene7919/Gene1799ArtCorporatione
- 📋 Actions Log: https://github.com/gene7919/Gene1799ArtCorporatione/actions
- 🔔 Telegram Bot: @gene1799_art_bot

---

## 💡 PRO TIPS

1. **Use local development first** to test locally before pushing
2. **Save secrets in GitHub, not in code**
3. **Test on testnet before mainnet** (Polygon Mumbai, Sepolia)
4. **Monitor Azure costs** - set alerts at $50/month
5. **Enable auto-scaling** for production workloads
6. **Backup your .env file** safely offline

---

## 📞 GETTING HELP

**Documentation:**
- 📖 WEB3_DAPPS_GUIDE.md - DeFi integration
- 📖 AZURE_INTEGRATION_GUIDE.md - Azure setup
- 📖 DEPLOYMENT_GUIDE.md - Production deployment
- 📖 All 46+ guides in repository

**Support:**
- 📧 Email: gene1799artcorporatione@gmail.com
- 🤖 Telegram: @gene1799_art_bot
- 💻 GitHub Issues: github.com/gene7919/Gene1799ArtCorporatione/issues

---

## 🎉 YOU'RE READY!

Choose your deployment path and run the script:

```powershell
# Windows PowerShell (Recommended)
.\setup-and-deploy.ps1

# Windows CMD
setup-and-deploy.bat

# Linux/Mac
./setup-and-deploy.sh

# Manual
npm install && npm run dev
```

**GENE1799 will be live in minutes!** 🚀

---

**Version**: 2.0.0 | **Date**: February 8, 2026 | **Status**: ✅ Production Ready
