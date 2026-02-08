# 🎼 Gene1799 Orchestrator System - Quick Start

A master orchestration system for coordinating all Gene1799 services and AI agents.

## 🚀 Quick Start (Under 2 Minutes)

### 1. **Validate System** (30 seconds)
```bash
python validate_orchestrator.py
```
This checks all components are in place and ready.

### 2. **Launch Orchestrator** (Choose One)

**Windows Batch:**
```batch
launch_orchestrator.bat
```

**PowerShell:**
```powershell
.\launch_orchestrator.ps1
```

**Direct Python:**
```bash
python orchestrator.py
```

### 3. **Start Services**
Once orchestrator starts, type:
```
orchestrator> start
```

This starts all services in the correct order:
- Backend API (Express.js) → port 3000
- Frontend Web (React) → port 3001  
- AI Agent (Python) → port 5000
- Desktop App (Electron) → optional

### 4. **Check System Health**
```
orchestrator> health
```

You'll see a JSON report of all services and agents.

### 5. **Monitor in Real-Time** (Optional)
Open another terminal:
```bash
python orchestrator_monitor.py
```

This shows a real-time dashboard of services and agents.

---

## 📁 Files in This System

### Core Orchestrator
- **`orchestrator.py`** (450+ lines)
  - Master orchestrator with interactive command mode
  - Manages 4 services + 5 AI agents
  - Async/await architecture

### Launchers
- **`launch_orchestrator.bat`** - Windows batch launcher
- **`launch_orchestrator.ps1`** - PowerShell launcher with colors
- Both check environment and validate before starting

### Monitoring
- **`orchestrator_monitor.py`** - Real-time monitoring dashboard
  - Shows service status (ports, uptime)
  - Lists AI agents and their roles
  - CPU/memory metrics

### Validation
- **`validate_orchestrator.py`** - Pre-launch system validation
  - Checks Python version
  - Verifies all required files exist
  - Validates configuration files
  - Reports any issues

### Documentation
- **`ORCHESTRATOR_GUIDE.md`** - Complete reference guide
  - Architecture overview
  - Service definitions
  - Agent descriptions
  - Troubleshooting
  - Production checklist

---

## 🏗️ What Gets Orchestrated?

### 4 Services
1. **Backend** - REST API on port 3000
   - Express.js + Node.js
   - Health endpoints
   - API routes

2. **Frontend** - Web UI on port 3001
   - React + TypeScript + Vite
   - Built SPA application
   - Connects to Backend

3. **AI Agent** - Python system on port 5000
   - Microsoft Agent Framework
   - Async processing
   - Azure AI integration

4. **Desktop** - Electron app (optional)
   - Cross-platform GUI
   - Native system integration

### 5 AI Agents
1. **Orchestrator** 🎼 - Master coordinator
2. **Data Processor** 📊 - ETL & processing
3. **Analytics** 📈 - Metrics & insights
4. **Communicator** 🔗 - Service integration
5. **Learning** 🧠 - ML & optimization

---

## ⌨️ Interactive Commands

Once orchestrator is running, use these commands:

| Command | What It Does |
|---------|------------|
| `start` | Start all services in dependency order |
| `stop` | Stop all services gracefully |
| `status` | Check what's running |
| `restart` | Restart all services |
| `health` | Full system health report |
| `agents` | List all AI agents |
| `help` | Show available commands |
| `exit` | Shutdown orchestrator |

---

## 📊 System Health Check

Get a complete system status:

```
orchestrator> health
```

Returns JSON like:
```json
{
  "status": "healthy",
  "timestamp": "2026-02-08T10:30:45.000Z",
  "services": {
    "backend": "operational",
    "frontend": "running",
    "ai-agent": "ready",
    "desktop": "stopped"
  },
  "agents": {
    "orchestrator": "initialized",
    "data-processor": "initialized",
    "analytics": "initialized",
    "communicator": "initialized",
    "learning": "initialized"
  }
}
```

---

## 🐛 Common Issues & Fixes

### Issue: "Python not found"
```bash
# Check Python is installed
python --version

# If not installed, download from python.org
```

### Issue: "Port 3000 already in use"
```bash
# Find what's using port 3000
netstat -ano | findstr :3000

# Kill the process (replace PID)
taskkill /PID 12345 /F
```

### Issue: "orchestrator.py not found"
```bash
# Make sure you're in Gene1799ArtCorporatione directory
cd c:\Users\gene1\Desktop\gene1799\Gene1799ArtCorporatione

# List files to verify
dir orchestrator.py
```

### Issue: "Python venv not activated"
```bash
# Activate Python virtual environment
cd ai-agent
venv\Scripts\activate

# Verify
python --version
```

---

## 🎯 Deployment to Render.com

When ready to deploy to production:

### 1. **Push to GitHub**
```bash
git add .
git commit "Deploy orchestrator system"
git push origin main
```

### 2. **Deploy to Render**
- Go to https://dashboard.render.com/select-repo?type=blueprint
- Select your GitHub repository
- Click "Deploy Blueprint"
- Wait 5-10 minutes for deployment

### 3. **Monitor Deployment**
- Check Render dashboard for logs
- Services should start automatically
- Health endpoint: `https://your-domain.onrender.com/api/health`

---

## 📚 Documentation

For complete documentation, see:

- **`ORCHESTRATOR_GUIDE.md`** - Full reference guide
  - Architecture diagrams
  - Service configurations
  - Agent capabilities
  - Troubleshooting
  - Production checklist

- **`DEPLOYMENT_READY.md`** - Deployment status
- **`SYSTEM_ORGANIZATION_COMPLETE.md`** - Full system overview
- **`RENDER_DEPLOYMENT.md`** - Render deployment guide

---

## ✅ Pre-Flight Checklist

Before running orchestrator:

- [ ] Run: `python validate_orchestrator.py`
- [ ] All services configured (backend, frontend, ai-agent)
- [ ] Environment files created (.env files)
- [ ] Python 3.9+ installed
- [ ] Node.js 20+ installed
- [ ] Port 3000 available
- [ ] Internet connection (for Azure services)

---

## 🔧 Advanced Usage

### Run with Debug Logging
```bash
python orchestrator.py --debug
```

### Run with Monitor
Terminal 1:
```bash
python orchestrator.py
orchestrator> start
```

Terminal 2:
```bash
python orchestrator_monitor.py
```

### Docker Stack (Local)
```bash
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

---

## 📞 Support

If you encounter issues:

1. **Check logs** - Review terminal output
2. **Validate system** - Run `python validate_orchestrator.py`
3. **Check ports** - Ensure 3000, 3001, 5000 are free
4. **Check services** - Verify backend, frontend, ai-agent are configured
5. **Review docs** - See ORCHESTRATOR_GUIDE.md for detailed help

---

## 📈 Next Steps

1. ✅ **Validate** - Run validation script
2. ✅ **Test Locally** - Start orchestrator and test services
3. ✅ **Build for Production** - `npm run build`
4. ✅ **Deploy to Render** - Push to GitHub and enable blueprint
5. ✅ **Monitor** - Use monitor dashboard for real-time visibility

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────┐
│    GENE1799 ORCHESTRATOR SYSTEM         │
├─────────────────────────────────────────┤
│                                         │
│  Services:                              │
│  • Backend (Express.js)  [port 3000]   │
│  • Frontend (React)      [port 3001]   │
│  • AI Agent (Python)     [port 5000]   │
│  • Desktop (Electron)    [optional]    │
│                                         │
│  AI Agents:                             │
│  • Orchestrator (Coordinator)           │
│  • Data Processor (Worker)              │
│  • Analytics (Analyzer)                 │
│  • Communicator (Connector)             │
│  • Learning (ML)                        │
│                                         │
│  Control:                               │
│  • Interactive CLI mode                 │
│  • Real-time monitor dashboard          │
│  • Health check endpoints               │
│  • JSON status reporting                │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📊 System Status

- ✅ Orchestrator: Production-ready
- ✅ Validation tool: Complete
- ✅ Monitor dashboard: Functional
- ✅ Documentation: Comprehensive
- ✅ Deployment config: Ready
- ✅ CI/CD pipelines: Active

---

**Version:** 1.0.0  
**Status:** ✅ Production Ready  
**Last Updated:** 2026-02-08  

**Ready to orchestrate? Type:** `python orchestrator.py`
