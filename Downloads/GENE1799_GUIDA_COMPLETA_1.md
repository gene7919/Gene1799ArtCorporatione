# ╔═══════════════════════════════════════════════════════════╗
# ║                                                           ║
# ║        🧠 GENE1799 AI INTEGRATION SYSTEM v2.0 🧠         ║
# ║                                                           ║
# ║           Guida Completa - Installazione & Uso           ║
# ║                                                           ║
# ╚═══════════════════════════════════════════════════════════╝

## 📋 PANORAMICA SISTEMA

GENE1799 è un sistema di intelligenza artificiale distribuito su multi-disco
che integra diversi provider AI e crea agenti specializzati che imparano.

### Architettura Multi-Disco:

- **C:\AI** - Core AI (modelli, cache, inferenza)
- **D:\Gene1799** - Hub centrale (database, logs, coordinamento)
- **D:\Electronic** - Sistemi elettronici (moduli hardware/software)
- **E:\GENE1799_AI** - Storage esteso AI (training, backup, provider)

### Provider AI Supportati:

1. **OpenAI** (GPT-4, GPT-3.5, DALL-E)
2. **Anthropic Claude** (Opus, Sonnet, Haiku)
3. **Google Gemini** (Pro, Vision)
4. **Hugging Face** (Mistral, Llama2, SD)
5. **Ollama** (Locale - Llama2, Mistral, CodeLlama)
6. **Stability AI** (Stable Diffusion)

## 🚀 INSTALLAZIONE RAPIDA

### Passo 1: Copia i file nel sistema

```powershell
# Crea directory principale
New-Item -Path "D:\Gene1799\Explorer" -ItemType Directory -Force

# Copia tutti gli script in D:\Gene1799\Explorer
# - gene1799_ai_integration_core.ps1
# - gene1799_ai_agent_system.ps1
# - gene1799_desktop_monitor_gui.ps1
```

### Passo 2: Inizializza il sistema

```powershell
cd D:\Gene1799\Explorer

# Abilita esecuzione script (solo la prima volta)
Set-ExecutionPolicy Bypass -Scope Process -Force

# Inizializza GENE1799 (crea tutte le directory e configurazioni)
.\gene1799_ai_integration_core.ps1 -Mode INIT
```

Questo creerà automaticamente:
- Tutte le directory su C:, D:, E:
- File di configurazione
- Template per API keys
- Database agenti
- Sistema di log
- Mappa connessioni sinaptiche

### Passo 3: Configura API Keys (opzionale)

```powershell
# Apri il file di configurazione API keys
.\gene1799_ai_integration_core.ps1 -Mode CONFIGURE

# Inserisci le tue API keys nel file JSON:
{
    "openai": "sk-...",
    "anthropic": "sk-ant-...",
    "google": "AIza...",
    "huggingface": "hf_...",
    "stability": "sk-..."
}

# IMPORTANTE: Mantieni questo file al sicuro!
# Path: D:\Gene1799\Database\.api_keys.json
```

### Passo 4: Test Provider AI

```powershell
# Testa TUTTI i provider
.\gene1799_ai_integration_core.ps1 -Mode TEST_API -Provider ALL

# Oppure testa un provider specifico
.\gene1799_ai_integration_core.ps1 -Mode TEST_API -Provider Ollama
.\gene1799_ai_integration_core.ps1 -Mode TEST_API -Provider OpenAI
```

### Passo 5: Crea il tuo primo agente

```powershell
# Crea un agente File Manager
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "FileBot" -AgentType "FILE_MANAGER"

# Crea un agente System Monitor
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "SysMonitor" -AgentType "SYSTEM_MONITOR"

# Crea un agente Code Assistant
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "CodeHelper" -AgentType "CODE_ASSISTANT"
```

### Passo 6: Addestra gli agenti

```powershell
# Addestra FileBot
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "FileBot"

# Addestra SysMonitor con più iterazioni
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "SysMonitor"
```

### Passo 7: Avvia la GUI di monitoraggio

```powershell
# Avvia l'interfaccia grafica
.\gene1799_desktop_monitor_gui.ps1
```

## 📊 COMANDI PRINCIPALI

### Sistema Core

```powershell
# Status completo del sistema
.\gene1799_ai_integration_core.ps1 -Mode STATUS

# Inizializza sistema
.\gene1799_ai_integration_core.ps1 -Mode INIT

# Testa tutti i provider
.\gene1799_ai_integration_core.ps1 -Mode TEST_API

# Configura API keys
.\gene1799_ai_integration_core.ps1 -Mode CONFIGURE
```

### Gestione Agenti

```powershell
# Lista tutti gli agenti
.\gene1799_ai_agent_system.ps1 -Mode LIST

# Crea nuovo agente
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "NomeAgente" -AgentType "TIPO"

# Addestra agente
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "NomeAgente"

# Esegui azione agente
.\gene1799_ai_agent_system.ps1 -Mode EXECUTE -AgentName "NomeAgente" -Task "azione"

# Status agente specifico
.\gene1799_ai_agent_system.ps1 -Mode STATUS -AgentName "NomeAgente"
```

## 🤖 TIPI DI AGENTI DISPONIBILI

### 1. FILE_MANAGER
**Descrizione:** Gestisce file, organizza cartelle, crea backup
**Azioni disponibili:**
- organize_downloads
- create_backup
- find_duplicates
- clean_temp_files
- smart_rename

**Esempio:**
```powershell
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "MyFileBot" -AgentType "FILE_MANAGER"
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "MyFileBot"
.\gene1799_ai_agent_system.ps1 -Mode EXECUTE -AgentName "MyFileBot" -Task "organize_downloads"
```

### 2. SYSTEM_MONITOR
**Descrizione:** Monitora risorse sistema, performance, allerte
**Azioni disponibili:**
- monitor_cpu
- monitor_memory
- monitor_disk
- check_processes
- performance_report

### 3. SECURITY_SCANNER
**Descrizione:** Scansiona minacce, gestisce permessi
**Azioni disponibili:**
- scan_vulnerabilities
- check_permissions
- monitor_network
- analyze_logs
- security_report

### 4. DATA_ANALYST
**Descrizione:** Analizza dati, genera report, insights
**Azioni disponibili:**
- analyze_data
- generate_report
- create_visualization
- predict_trends
- summarize_insights

### 5. AUTOMATION_BOT
**Descrizione:** Esegue task automatici, scheduling
**Azioni disponibili:**
- schedule_task
- execute_workflow
- monitor_jobs
- send_notifications
- integrate_apis

### 6. CODE_ASSISTANT
**Descrizione:** Aiuta con coding, debugging, review
**Azioni disponibili:**
- generate_code
- debug_error
- refactor_code
- write_documentation
- code_review

### 7. CONTENT_CREATOR
**Descrizione:** Crea contenuti, documenti, presentazioni
**Azioni disponibili:**
- write_document
- create_presentation
- generate_image
- format_content
- translate_text

### 8. NETWORK_MANAGER
**Descrizione:** Gestisce reti, connessioni, traffico
**Azioni disponibili:**
- monitor_connections
- analyze_traffic
- test_bandwidth
- diagnose_issues
- optimize_network

## 🎯 ESEMPI PRATICI

### Scenario 1: Setup Sistema Completo

```powershell
# 1. Inizializza
.\gene1799_ai_integration_core.ps1 -Mode INIT

# 2. Configura API (opzionale)
.\gene1799_ai_integration_core.ps1 -Mode CONFIGURE

# 3. Crea 3 agenti diversi
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "FileMaster" -AgentType "FILE_MANAGER"
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "SysGuard" -AgentType "SYSTEM_MONITOR"
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "CodeBuddy" -AgentType "CODE_ASSISTANT"

# 4. Addestra tutti
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "FileMaster"
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "SysGuard"
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "CodeBuddy"

# 5. Verifica status
.\gene1799_ai_integration_core.ps1 -Mode STATUS
.\gene1799_ai_agent_system.ps1 -Mode LIST

# 6. Avvia GUI
.\gene1799_desktop_monitor_gui.ps1
```

### Scenario 2: Solo Ollama (Locale - No API Keys)

```powershell
# 1. Installa Ollama (se non già installato)
# Scarica da: https://ollama.ai

# 2. Avvia Ollama
ollama serve

# 3. Scarica modelli
ollama pull llama2
ollama pull mistral
ollama pull codellama

# 4. Inizializza GENE1799
.\gene1799_ai_integration_core.ps1 -Mode INIT

# 5. Testa Ollama
.\gene1799_ai_integration_core.ps1 -Mode TEST_API -Provider Ollama

# 6. Crea agente con Ollama
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "LocalBot" -AgentType "CODE_ASSISTANT" -AIProvider "Ollama"

# 7. Addestra
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "LocalBot"
```

### Scenario 3: Team di Agenti Specializzati

```powershell
# Crea un team di agenti per gestione completa sistema

# Security Team
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "SecurityScanner" -AgentType "SECURITY_SCANNER"
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "NetworkGuard" -AgentType "NETWORK_MANAGER"

# Operations Team
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "SysMonitor" -AgentType "SYSTEM_MONITOR"
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "FileOrganizer" -AgentType "FILE_MANAGER"

# Development Team
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "CodeAssist" -AgentType "CODE_ASSISTANT"
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "DataAnalyst" -AgentType "DATA_ANALYST"

# Addestra tutto il team
$agents = @("SecurityScanner", "NetworkGuard", "SysMonitor", "FileOrganizer", "CodeAssist", "DataAnalyst")
foreach ($agent in $agents) {
    .\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName $agent
}

# Lista il team
.\gene1799_ai_agent_system.ps1 -Mode LIST
```

## 📁 STRUTTURA FILE SYSTEM

```
C:\AI\
├── Models\              # Modelli AI locali
├── Agents\              # Agenti (copia locale)
└── Cache\               # Cache inferenza

D:\Gene1799\
├── Modules\             # Moduli sistema
├── Agents\              # Agenti (configurazioni)
│   ├── AgentName\
│   │   ├── config.json
│   │   └── agent.ps1
├── Synaptic\            # Rete sinaptica
│   ├── Weights\         # Pesi neurali
│   └── connection_map.json
├── Logs\                # Log sistema
│   └── ai_integration.log
├── Database\            # Database
│   ├── agents.json
│   ├── ai_config.json
│   └── .api_keys.json
└── Explorer\            # Script principali
    ├── gene1799_ai_integration_core.ps1
    ├── gene1799_ai_agent_system.ps1
    └── gene1799_desktop_monitor_gui.ps1

D:\Electronic\
├── Modules\             # Moduli elettronici
└── Data\                # Dati elettronici

E:\GENE1799_AI\
├── Models\              # Storage modelli esteso
│   └── AgentName\
├── Training\            # Dati training
│   └── AgentName\
├── Results\             # Risultati AI
├── Backups\             # Backup
└── Providers\           # Provider-specific
    ├── OpenAI\
    ├── Anthropic\
    ├── Google\
    ├── HuggingFace\
    ├── Ollama\
    └── StabilityAI\
```

## 🔧 TROUBLESHOOTING

### Problema: Script non riconosciuto

```powershell
# Soluzione: Imposta execution policy
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### Problema: Disco E: non esiste

```powershell
# Soluzione 1: Crea un virtual disk
# o
# Soluzione 2: Modifica lo script per usare altro disco
# Cerca "E:\GENE1799_AI" e sostituisci con "D:\GENE1799_AI_Extended"
```

### Problema: Provider OFFLINE

```powershell
# 1. Verifica API keys
.\gene1799_ai_integration_core.ps1 -Mode CONFIGURE

# 2. Testa connessione
.\gene1799_ai_integration_core.ps1 -Mode TEST_API -Provider NomeProvider

# 3. Per Ollama: verifica che sia in esecuzione
ollama serve
```

### Problema: Agente non si addestra

```powershell
# 1. Verifica che l'agente esista
.\gene1799_ai_agent_system.ps1 -Mode LIST

# 2. Verifica lo status
.\gene1799_ai_agent_system.ps1 -Mode STATUS -AgentName "NomeAgente"

# 3. Ricrea l'agente se necessario
.\gene1799_ai_agent_system.ps1 -Mode DELETE -AgentName "NomeAgente"
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "NomeAgente" -AgentType "TIPO"
```

## 🎨 GUI DESKTOP MONITOR

La GUI fornisce:

### Dashboard Overview
- Status multi-disco (C:, D:, E:)
- Status provider AI
- Metriche sistema (CPU, RAM)
- Statistiche agenti

### Gestione Agenti
- Lista agenti con status
- Creazione nuovi agenti
- Training agenti
- Esecuzione task

### System Logs
- Visualizzazione log real-time
- Export log
- Auto-refresh

### Network Visualization
- Mappa connessioni sinaptiche
- Visualizzazione rete agenti

## 🔐 SICUREZZA

### API Keys
- **Mai committare** .api_keys.json in repository
- Usa variabili d'ambiente per production
- Ruota le chiavi periodicamente

### File Permissions
```powershell
# Proteggi file sensibili
$apiKeysFile = "D:\Gene1799\Database\.api_keys.json"
$acl = Get-Acl $apiKeysFile
$acl.SetAccessRuleProtection($true, $false)
Set-Acl $apiKeysFile $acl
```

## 📈 ROADMAP FUTURE

- [ ] Integrazione real AI training (non simulato)
- [ ] Agent collaboration (agenti che lavorano insieme)
- [ ] Web interface (oltre GUI desktop)
- [ ] Cloud sync (backup su cloud)
- [ ] Mobile monitoring app
- [ ] Voice control per agenti
- [ ] Auto-learning da task history
- [ ] Plugin system per estensioni

## 📞 SUPPORTO

### Log Files
- Sistema: `D:\Gene1799\Logs\ai_integration.log`
- Agenti: `D:\Gene1799\Logs\Agents\{AgentName}\`

### Database Files
- Agenti: `D:\Gene1799\Database\agents.json`
- Config: `D:\Gene1799\Database\ai_config.json`
- Provider Status: `D:\Gene1799\Database\provider_status.json`

## 🎓 BEST PRACTICES

1. **Inizia con Ollama** (locale, gratuito)
2. **Addestra agenti progressivamente** (100 → 200 → 500 iterations)
3. **Monitora disk space** su E: (training data può crescere)
4. **Backup regolari** del database agenti
5. **Test provider** prima di usarli in production
6. **Usa GUI** per monitoraggio visuale
7. **Check logs** per troubleshooting

## 🏁 QUICK START MINIMAL

```powershell
# 1 minuto setup
cd D:\Gene1799\Explorer
.\gene1799_ai_integration_core.ps1 -Mode INIT
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "Bot1" -AgentType "FILE_MANAGER"
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "Bot1"
.\gene1799_desktop_monitor_gui.ps1
```

---

## ✨ Buon lavoro con GENE1799 AI System! ✨

Per domande o problemi, consulta i log o ricrea l'ambiente.
