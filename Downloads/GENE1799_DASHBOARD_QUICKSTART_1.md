# 🎨 GENE1799 ART CORPORATION - Dashboard Connector v1.0

## Quick Start Guide

### ⚡ Installation (5 minutes)

1. **Download the script**
   - Get `gene1799_dashboard_connector.ps1` from outputs

2. **Copy to Explorer folder**
   ```powershell
   Copy-Item gene1799_dashboard_connector.ps1 D:\Gene1799\Explorer\
   ```

3. **Set execution policy**
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   ```

---

## 🚀 Usage Commands

### 1. Initialize Dashboard Connection
```powershell
cd D:\Gene1799\Explorer
.\gene1799_dashboard_connector.ps1 -Mode INIT -DashboardHost localhost -DashboardPort 8080
```

### 2. Check Dashboard Status
```powershell
.\gene1799_dashboard_connector.ps1 -Mode STATUS
```

### 3. Test Connection
```powershell
.\gene1799_dashboard_connector.ps1 -Mode CONNECT
```

### 4. Sync System with Dashboard
```powershell
.\gene1799_dashboard_connector.ps1 -Mode SYNC
```

---

## 📁 Directory Structure Created

```
D:\Gene1799\
├── config/
│   └── dashboard.json
├── agents/
│   ├── Hub/
│   ├── Semantic/
│   └── Medical/
├── Modules/
│   └── [Core modules]
├── Logs/
│   └── dashboard_connector.log
└── Explorer/
    └── gene1799_dashboard_connector.ps1
```

---

## 📊 Configuration File

After INIT, check: `D:\Gene1799\config\dashboard.json`

```json
{
  "version": "1.0",
  "host": "localhost",
  "port": 8080,
  "apiKey": "",
  "status": "INITIALIZED",
  "endpoints": {
    "agents": "/api/v1/agents",
    "orchestrator": "/api/v1/orchestrator",
    "logs": "/api/v1/logs",
    "status": "/api/v1/status"
  }
}
```

---

## 📋 Log Files

Location: `D:\Gene1799\Logs\dashboard_connector.log`

View logs:
```powershell
Get-Content "D:\Gene1799\Logs\dashboard_connector.log" -Tail 20
```

---

## ⚠️ Troubleshooting

### Script Not Found
```powershell
# Check location
Get-Item D:\Gene1799\Explorer\gene1799_dashboard_connector.ps1

# Unblock if needed
Unblock-File D:\Gene1799\Explorer\gene1799_dashboard_connector.ps1
```

### Connection Fails
```powershell
# Check port
Test-NetConnection -ComputerName localhost -Port 8080
```

### Missing Config
```powershell
# Reinitialize
.\gene1799_dashboard_connector.ps1 -Mode INIT
```

---

## ✅ Success Checklist

- [ ] Script copied to `D:\Gene1799\Explorer\`
- [ ] Execution policy set to Bypass
- [ ] INIT mode completed
- [ ] `dashboard.json` created
- [ ] All directories exist
- [ ] SYNC shows agents and modules

---

**Status**: Ready for Dashboard Connection  
**Version**: 1.0  
**Last Updated**: 2026-02-04
