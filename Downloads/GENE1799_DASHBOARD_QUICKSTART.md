# 🎨 GENE1799 ART CORPORATION - DASHBOARD CONNECTION GUIDE

## Quick Start

### 1. **Initialize Dashboard Connection**
```powershell
cd D:\Gene1799\Explorer
Set-ExecutionPolicy Bypass -Scope Process -Force

# Download the dashboard connector script (paste the script above)
# Then run:
.\gene1799_dashboard_connector.ps1 -Mode INIT -DashboardHost localhost -DashboardPort 8080
```

### 2. **Check Dashboard Status**
```powershell
.\gene1799_dashboard_connector.ps1 -Mode STATUS
```

### 3. **Test Connection**
```powershell
.\gene1799_dashboard_connector.ps1 -Mode CONNECT -DashboardHost yourdomain.com -DashboardPort 8080
```

### 4. **Sync System Data**
```powershell
.\gene1799_dashboard_connector.ps1 -Mode SYNC
```

---

## **File Structure Required**

```
D:\Gene1799\
├── config/
│   ├── dashboard.json          ← Dashboard configuration
│   ├── agents.json             ← Agent manifest
│   └── core.settings.json      ← System settings
├── agents/
│   ├── Hub/
│   ├── Semantic/
│   ├── Medical/
│   └── [other agents...]
├── Modules/
│   ├── Gene1799Core/
│   └── Gene1799Extensions/
├── Logs/
│   ├── dashboard_connector.log
│   └── master_orchestrator.log
└── Explorer/
    ├── gene1799_dashboard_connector.ps1
    └── hub_explorer.ps1
```

---

## **Key Commands**

| Mode | Description | Command |
|------|-------------|---------|
| **INIT** | Initialize dashboard | `.\connector.ps1 -Mode INIT` |
| **STATUS** | Check system status | `.\connector.ps1 -Mode STATUS` |
| **CONNECT** | Test dashboard connection | `.\connector.ps1 -Mode CONNECT` |
| **SYNC** | Sync agents & modules | `.\connector.ps1 -Mode SYNC` |

---

## **Dashboard Configuration**

After initialization, check `D:\Gene1799\config\dashboard.json`:

```json
{
  "version": "1.0",
  "host": "localhost",
  "port": 8080,
  "apiKey": "YOUR_API_KEY",
  "status": "CONNECTED",
  "endpoints": {
    "agents": "/api/v1/agents",
    "orchestrator": "/api/v1/orchestrator",
    "logs": "/api/v1/logs",
    "status": "/api/v1/status"
  }
}
```

---

## **Troubleshooting**

### **Connection Fails**
```powershell
# Verify dashboard is running
Test-NetConnection -ComputerName localhost -Port 8080

# Check firewall
Get-NetFirewallRule -DisplayName "*8080*"
```

### **Missing Config Files**
```powershell
# Reinitialize
.\gene1799_dashboard_connector.ps1 -Mode INIT -DashboardHost localhost -DashboardPort 8080
```

### **View Logs**
```powershell
Get-Content "D:\Gene1799\Logs\dashboard_connector.log" -Tail 50
```

---

## **Next Steps**

1. ✅ Copy `gene1799_dashboard_connector.ps1` to `D:\Gene1799\Explorer\`
2. ✅ Run `INIT` mode to create config
3. ✅ Run `STATUS` to verify setup
4. ✅ Run `SYNC` to connect with dashboard
5. ✅ Access dashboard at `https://localhost:8080/api/v1/gene1799/status`

---

**Status**: Ready for Dashboard Connection  
**Version**: 1.0  
**Last Updated**: 2026-02-04
