# Gene1799 Orchestrator - Desktop GUI

## 🎯 Overview

**Professional GUI desktop application** per controllare l'orchestrator Gene1799 con integrazione completa della GPU NVIDIA RTX 4070 e degli agenti specializzati.

## 🚀 Features

### Core Features
- ✅ **Service Management** - Start/stop/restart all services
- ✅ **GPU Monitoring** - Real-time RTX 4070 status
- ✅ **AI Agents Dashboard** - Monitor 5 orchestrator agents
- ✅ **Specialized Agents** - Integration with medical, pharma, healthcare agents
- ✅ **System Metrics** - CPU, Memory, Disk monitoring
- ✅ **Report Generation** - Automated system reports
- ✅ **AI Solutions** - Intelligent problem-solving from specialized agents

### Services Managed
- **Backend API** (Express.js) - Port 3000
- **Frontend Web** (React) - Port 5173
- **AI Agent System** (Python) - Port 8000
- **Desktop Application** (Electron) - Optional

### AI Agents Orchestrated
1. **System Orchestrator** - Master coordinator
2. **Data Processor** - Data processing/transformation
3. **Analytics Agent** - Metrics and insights
4. **Communication Agent** - Service integration
5. **Machine Learning Agent** - ML operations

### Specialized Agents
- **Anti-Cancer AI Engine** - Medical oncology modeling
- **Drug Discovery Engine** - Pharmaceutical research
- **Healthcare Integration** - EHR/patient data analytics
- **Multi-Agent Orchestrator** - Workflow coordination

## 📋 Requirements

### System Requirements
- Windows 10/11 or Linux
- Python 3.9+
- NVIDIA RTX 4070 (or compatible NVIDIA GPU)
- 8GB RAM minimum
- 2GB Disk space

### Python Dependencies
```
tkinter (built-in)
psutil
pynvml (NVIDIA GPU monitoring)
```

## 🏃 Quick Start

### Method 1: Batch Launcher (Windows)
```batch
launch_orchestrator_gui.bat
```

### Method 2: Direct Python
```bash
python orchestrator_gui.py
```

### Method 3: PowerShell
```powershell
python orchestrator_gui.py
```

## 🎨 GUI Layout

```
┌─────────────────────────────────────────────────────────────────┐
│        GENE1799 ORCHESTRATOR - GPU ACCELERATED                  │
│                                    STATUS: READY                │
├──────────────────┬──────────────────┬──────────────────────────┤
│                  │                  │                          │
│    SERVICES      │    AI AGENTS     │   GPU & REPORTS          │
│                  │                  │                          │
│ ✓ Backend      │ ✓ Orchestrator  │ RTX 4070 Status:         │
│ □ Frontend     │ ✓ Processor     │ GPU: ...                 │
│ ✓ AI Agent     │ ✓ Analytics     │ Memory: ...              │
│ ✓ Desktop      │ ✓ Communicator  │ Temp: ...                │
│                │ ✓ Learning      │                          │
│                │                 │ [Generate Report]        │
│                │ Specialized:    │ [Get Solutions]          │
│                │ • antiCancer    │                          │
│                │ • drugDiscovery │ System Info:             │
│                │ • healthcare    │ CPU: ...                 │
│                │                 │ Memory: ...              │
├──────────────────────────────────────────────────────────────────┤
│ [START ALL] [STOP ALL] [RESTART] [HEALTH CHECK] [EXIT]          │
└──────────────────────────────────────────────────────────────────┘
```

## 🎮 Key Controls

### Service Management Buttons
- **[RUNNING]** - Green button, service is active
- **[STOPPED]** - Red button, service is inactive
- Click any button to toggle service state

### Control Panel
- **START ALL** - Launches all services in dependency order
- **STOP ALL** - Gracefully stops all services
- **RESTART** - Stops then starts all services
- **HEALTH CHECK** - Full system diagnostics
- **EXIT** - Closes GUI and stops orchestrator

### Report Buttons
- **Generate Report** - Creates comprehensive system report
- **Get Solutions** - AI-powered problem-solving recommendations

## 📊 Monitoring

### GPU Monitoring
- Real-time RTX 4070 status
- GPU memory usage
- Temperature monitoring
- Utilization percentage

### System Metrics
- CPU usage percentage
- RAM (used/total)
- Disk space (used/total)
- Real-time updates every 3 seconds

### Service Status
- Individual service state display
- Port information
- Service-specific metrics

## 🤖 AI Solutions Engine

### How It Works
1. **Analyze** - Specialized agents analyze the problem domain
2. **Recommend** - Each agent provides domain-specific solutions
3. **Orchestrate** - Orchestrator agents coordinate implementation
4. **Execute** - GPU-accelerated execution of recommendations
5. **Report** - Generate insights and next steps

### Solution Categories

**Medical Solutions** (Anti-Cancer Engine)
- Oncology modeling optimization
- Drug target identification
- Clinical trial acceleration
- Diagnostic improvement

**Pharmaceutical Solutions** (Drug Discovery)
- Molecular docking acceleration
- Compound screening optimization
- Lead candidate identification
- Synthetic route planning

**Healthcare Solutions** (Healthcare Integration)
- EHR system integration
- Patient outcome prediction
- Treatment optimization
- Telemedicine support

**System Solutions** (Orchestrator)
- Resource optimization
- Performance improvement
- Workflow enhancement
- Infrastructure scaling

## 📈 Report Generation

### Automatic Reports Include
- Timestamp and run identifier
- Service status snapshot
- Agent operational status
- GPU performance metrics
- System resource usage
- Specialized agent recommendations
- Implementation roadmap
- Next recommended actions

### Report Location
Reports are saved to: `report_YYYYMMDD_HHMMSS.txt`

## 🔧 Configuration

### Environment Variables
Set before launching GUI:

```bash
# GPU configuration
CUDA_VISIBLE_DEVICES=0          # Use first GPU

# System configuration
AGENT_DEBUG=False               # Disable debug mode
MAX_THREADS=8                   # Max worker threads
REPORT_INTERVAL=3600            # Report generation interval (seconds)

# Specialized agents
ENABLE_MEDICAL_AGENTS=true      # Enable anti-cancer engine
ENABLE_PHARMA_AGENTS=true       # Enable drug discovery
ENABLE_HEALTHCARE=true          # Enable healthcare integration
```

## 🐛 Troubleshooting

### GUI Won't Start
```bash
# Check Python installation
python --version

# Install missing dependencies
pip install psutil pynvml
```

### GPU Not Detected
```bash
# Verify NVIDIA GPU drivers
nvidia-smi

# Install NVIDIA monitoring
pip install pynvml
```

### Services Won't Start
```bash
# Check if ports are available
netstat -ano | findstr :3000

# Verify orchestrator is running
python orchestrator_fixed.py
```

### Report Generation Fails
```bash
# Check write permissions
# Ensure disk space is available
# Verify project directory access
```

## 📁 Files

- `orchestrator_gui.py` - Main GUI application
- `orchestrator_fixed.py` - Backend orchestrator (must be running)
- `ai_solutions_engine.py` - AI solutions generator
- `launch_orchestrator_gui.bat` - Windows launcher
- `ORCHESTRATOR_GUI_README.md` - This file

## 🚀 Advanced Usage

### Headless Mode
For server/CLI-only environments, use:
```bash
python orchestrator_fixed.py
```

### Integration with External Systems
Export reports as JSON:
```bash
# Reports are automatically JSON-formatted
cat report_*.txt | jq .
```

### Custom Agent Integration
Add specialized agents by editing `ai_solutions_engine.py`:
```python
self.specialized_agents['custom'] = SpecializedAgent(
    name='Custom Agent',
    specialization=AgentSpecialization.MEDICAL,
    capabilities=['custom_capability'],
    file_path='path/to/agent.js'
)
```

## 📊 Performance Tips

### GPU Optimization
1. Keep GPU drivers updated
2. Monitor thermal conditions
3. Disable unnecessary background processes
4. Use dedicated GPU for orchestrator tasks
5. Implement dynamic batching for workloads

### CPU Optimization
1. Distribute workload across cores
2. Use async operations
3. Enable lazy loading
4. Optimize report generation frequency
5. Implement caching for metrics

### Memory Optimization
1. Monitor memory usage continuously
2. Implement garbage collection cycles
3. Use streaming for large reports
4. Clear old report files periodically
5. Optimize GUI update frequency

## 🔐 Security

### Best Practices
- ✅ Run in isolated environment
- ✅ Restrict port access
- ✅ Use environment variables for secrets
- ✅ Enable logging and monitoring
- ✅ Regular security updates

### Data Protection
- Reports contain sensitive information
- Store reports securely
- Implement access controls
- Encrypt sensitive data
- Regular backups

## 📞 Support

### Common Issues

**Issue: "No module named 'tkinter'"**
```bash
# Install tkinter
# Windows: Usually included with Python
# Linux: sudo apt-get install python3-tk
# macOS: brew install python-tk
```

**Issue: "GPU not found"**
```bash
# Install GPU monitoring
pip install pynvml

# Verify NVIDIA drivers
nvidia-smi
```

**Issue: "Port already in use"**
```bash
# Stop existing processes
taskkill /PID <pid> /F

# Use different port (edit orchestrator_fixed.py)
```

## 🎯 Next Steps

1. ✅ Launch GUI: `python orchestrator_gui.py`
2. ✅ Start all services: Click [START ALL]
3. ✅ Monitor status: Watch real-time updates
4. ✅ Generate report: Click [Generate Report]
5. ✅ Get solutions: Click [Get Solutions]
6. ✅ Implement recommendations: Follow roadmap

## 📚 Documentation

- [ORCHESTRATOR_GUIDE.md](ORCHESTRATOR_GUIDE.md) - Complete reference
- [ORCHESTRATOR_README.md](ORCHESTRATOR_README.md) - Quick start
- [DEPLOYMENT_READY.md](DEPLOYMENT_READY.md) - Deployment info

## 🎉 Features Summary

| Feature | Status | Notes |
|---------|--------|-------|
| Service Management | ✅ | Full control |
| GPU Monitoring | ✅ | RTX 4070 support |
| AI Agents | ✅ | 5 orchestrator + 4 specialized |
| Reporting | ✅ | Auto-generated, JSON format |
| Solutions Engine | ✅ | Domain-specific recommendations |
| System Metrics | ✅ | Real-time monitoring |
| Dark Theme | ✅ | Professional look |
| Cross-Platform | ✅ | Windows, Linux, macOS |

## 📝 License

Gene1799 Platform - All Rights Reserved

---

**Version:** 1.0.0  
**Last Updated:** 2026-02-08  
**Status:** ✅ Production Ready  

**Ready to orchestrate with GPU acceleration?**
```bash
python orchestrator_gui.py
```
