# 🚀 GENE1799 LOCAL PROTOTYPE - START HERE

**Time to Live: 2 minutes**

---

## ⚡ QUICK START

### Windows - PowerShell (Recommended)
```powershell
cd Desktop\gene1799artcorporatione
.\start-prototype.ps1
```

### Windows - Command Prompt
```cmd
cd Desktop\gene1799artcorporatione
start-prototype.bat
```

### Linux/Mac
```bash
cd Desktop/gene1799artcorporatione
chmod +x start-prototype.sh
./start-prototype.sh
```

### Manual Start
```bash
npm install
node start-prototype.js
```

---

## 🌐 ACCESS POINTS (Once Running)

**Dashboard:**
- http://localhost:3000

**Web3 dApps Manager:**
- http://localhost:3000/web3-dapps-dashboard.html

**Backend API:**
- http://localhost:3001

**Telegram Bot:**
- @gene1799_art_bot (if configured)

---

## 📋 WHAT'S INCLUDED

✅ **Backend Services**
- Orchestrator (Task dispatcher)
- Learning Agents (AI)
- Web3 dApps (Uniswap, Aave, Lido, etc)
- Telegram Bot
- Security Matrix

✅ **Frontend Interfaces**
- System Dashboard
- Web3 Portfolio Manager
- Real-time Monitoring

✅ **Database**
- SQLite (local development)
- Can upgrade to PostgreSQL

✅ **Monitoring**
- Real-time metrics
- Event logging
- Error tracking

---

## 🔑 CONFIGURE BEFORE FIRST RUN

Edit `backend/.env`:

```bash
# RPC Endpoints (free options)
ETH_RPC_URL=https://eth.llamarpc.com
POLYGON_RPC_URL=https://polygon-rpc.com

# Wallet (OPTIONAL - local testing)
WALLET_ADDRESS=0x...

# Telegram (OPTIONAL)
TELEGRAM_BOT_TOKEN=your_token
```

---

## ✅ VERIFICATION

After starting, you'll see:

```
✓ Node.js 18.x.x
✓ npm 9.x.x
✓ backend/src found
✓ frontend found
✓ telegram-bot found
✓ Environment configured
✓ Dependencies installed

LAUNCHING PROTOTYPE SYSTEM

Services starting:
  📊 Dashboard       → http://localhost:3000
  🌐 Web3 dApps      → http://localhost:3000/web3-dapps-dashboard.html
  🔌 Backend API     → http://localhost:3001
  🤖 Telegram Bot    → Polling active
```

---

## 🎯 WHAT TO TEST

1. **Dashboard** (http://localhost:3000)
   - See real-time system metrics
   - Monitor agent activity
   - View system logs

2. **Web3 Dashboard** (http://localhost:3000/web3-dapps-dashboard.html)
   - Portfolio overview
   - Token balances
   - DeFi operations interface
   - Multi-chain support

3. **API Health**
   ```bash
   curl http://localhost:3001/health
   # Should return { status: "ok" }
   ```

4. **Modules**
   Test each module loads:
   ```javascript
   const orch = require('./backend/src/orchestrator-core');
   const web3 = require('./backend/src/web3-dapps-integration');
   const bot = require('./telegram-bot/bot');
   // All should load without errors
   ```

---

## 🛑 STOP SERVICES

Press **Ctrl+C** to gracefully stop all services:
```
Shutting down services...
✓ Stopped Backend
✓ Stopped Bot
✓ Stopped Dashboard
All services stopped
```

---

## 📊 SYSTEM ARCHITECTURE (Local)

```
YOUR PC
├── Browser (Port 3000)
│   ├── Dashboard
│   └── Web3 Manager
├── Backend Server (Port 3001)
│   ├── Orchestrator
│   ├── Learning Agents
│   ├── Web3 Integration
│   └── API Endpoints
├── Telegram Bot
│   └── Polling notifications
└── Storage (SQLite)
    └── Local database
```

---

## 🐛 TROUBLESHOOTING

### "Node.js not found"
→ Install from https://nodejs.org (18+ LTS)

### "npm install fails"
→ Try: `npm install --legacy-peer-deps`

### "Port 3000 already in use"
→ Change in start-prototype.js or kill existing process

### "Cannot find backend/src"
→ Make sure you're in correct directory: `cd Desktop\gene1799artcorporatione`

### "Dashboard shows nothing"
→ Open browser console (F12) to see errors
→ Check backend is running (port 3001)

### ".env configuration"
→ Create from template: `cp backend/.env.example backend/.env`
→ Edit with your RPC endpoints

---

## 📈 NEXT STEPS

After running locally:

1. **Test locally** (you are here)
2. **Deploy to Render** (fast, free)
3. **Deploy to Azure** (production)
4. **Deploy to Docker** (containerized)

Run: `.\setup-and-deploy.ps1` to deploy

---

## 🔗 USEFUL COMMANDS

```bash
# Clear cache/rebuild
rm -rf node_modules package-lock.json
npm install

# Run with debug output
DEBUG=* node start-prototype.js

# Run specific module only
node backend/src/orchestrator-core.js

# Test Web3 integration
node -e "const w = require('./backend/src/web3-dapps-integration'); console.log('✓ Web3 loaded')"

# Test Telegram bot
node telegram-bot/bot.js
```

---

## 📞 SUPPORT

**Questions?**
- 📖 Read: QUICK_START.md
- 📖 Read: WEB3_DAPPS_GUIDE.md
- 🤖 Ask: @gene1799_art_bot on Telegram
- 📧 Email: gene1799artcorporatione@gmail.com

---

## 🎉 YOU'RE READY!

```bash
# Choose one:

# PowerShell (Windows)
.\start-prototype.ps1

# Batch (Windows)
start-prototype.bat

# Bash (Linux/Mac)
./start-prototype.sh

# Node (Any OS)
node start-prototype.js
```

**System will be live in seconds!** ✅

---

**Version**: 2.0.0 | **Type**: Local Prototype | **Status**: ✅ Ready
