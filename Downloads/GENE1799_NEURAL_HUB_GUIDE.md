# 🧠 GENE1799 NEURAL HUB - Complete System Guide

## 📋 Overview

**GENE1799 Neural Hub** è un sistema avanzato di gestione agenti AI con architettura sinaptica che connette:

- **C:\AI** - Core AI e modelli di inferenza
- **D:\Gene1799** - Hub centrale e coordinamento agenti
- **D:\Electronic** - Integrazione sistemi elettronici

Il sistema permette di creare, addestrare e gestire agenti AI specializzati con reti neurali sinaptiche.

---

## 🎯 Architettura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    🧠 GENE1799 NEURAL HUB                   │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼────┐          ┌────▼────┐          ┌────▼────┐
   │ C:\AI   │◄────────►│D:\Gene  │◄────────►│D:\Elect │
   │  Core   │          │  1799   │          │  ronic  │
   └─────────┘          └─────────┘          └─────────┘
        │                     │                     │
   ┌────▼────┐          ┌────▼────┐          ┌────▼────┐
   │ Models  │          │ Agents  │          │ Modules │
   │ Agents  │          │Synaptic │          │  Data   │
   └─────────┘          └─────────┘          └─────────┘
```

### Connessioni Sinaptiche

- **Peso sinaptico C:\AI ↔ D:\Gene1799**: 1.0
- **Peso sinaptico D:\Gene1799 ↔ D:\Electronic**: 1.0
- **Peso sinaptico C:\AI ↔ D:\Electronic**: 0.8

---

## 🚀 Quick Start

### Step 1: Copia gli Script

Copia questi 3 file in `D:\Gene1799\Explorer`:
1. `gene1799_neural_hub.ps1` - Core system
2. `gene1799_gui.ps1` - GUI interattiva
3. `hub_explorer_FIXED.ps1` - File manager (già creato)

### Step 2: Inizializzazione del Sistema

```powershell
# Apri PowerShell come Amministratore
cd D:\Gene1799\Explorer
Set-ExecutionPolicy Bypass -Scope Process -Force

# Inizializza il Neural Hub
.\gene1799_neural_hub.ps1 -Mode INIT
```

Questo creerà automaticamente:
```
C:\AI\
  ├── Models\
  └── Agents\

D:\Gene1799\
  ├── Modules\
  ├── Agents\
  ├── Synaptic\
  │   ├── Weights\
  │   └── connection_map.json
  ├── Database\
  │   └── agents.json
  └── Logs\
      └── neural_hub.log

D:\Electronic\
  ├── Modules\
  ├── Data\
  └── Agents\
```

### Step 3: Avvia la GUI (Opzionale)

```powershell
.\gene1799_gui.ps1
```

---

## 🤖 Gestione Agenti

### Creare un Nuovo Agente

#### Metodo 1: Linea di Comando

```powershell
.\gene1799_neural_hub.ps1 -Mode ADD_AGENT -AgentName "VisionClassifier" -AgentType "CLASSIFIER"
```

#### Metodo 2: GUI

1. Avvia `gene1799_gui.ps1`
2. Inserisci il nome dell'agente
3. Seleziona il tipo (CLASSIFIER, PREDICTOR, etc.)
4. Clicca "➕ Add Agent"

### Tipi di Agenti Disponibili

| Tipo | Descrizione | Uso Tipico |
|------|-------------|------------|
| **CLASSIFIER** | Classificazione dati | Riconoscimento immagini, categorizzazione |
| **PREDICTOR** | Previsione valori | Forecasting, predizione serie temporali |
| **GENERATOR** | Generazione contenuti | Creazione testi, immagini, dati sintetici |
| **ANALYZER** | Analisi complessa | Pattern recognition, anomaly detection |
| **OPTIMIZER** | Ottimizzazione parametri | Tuning hyperparameters, resource allocation |
| **GENERAL** | Uso generico | Task multipli, prototipazione |

### Struttura di un Agente

Ogni agente creato ha:

```json
{
  "id": "unique-guid",
  "name": "AgentName",
  "type": "CLASSIFIER",
  "status": "INITIALIZED",
  "synaptic_layers": [
    {
      "layer_id": 1,
      "neurons": 128,
      "activation": "ReLU",
      "connections": ["INPUT", "HIDDEN_1"]
    },
    {
      "layer_id": 2,
      "neurons": 64,
      "activation": "ReLU",
      "connections": ["HIDDEN_1", "HIDDEN_2"]
    },
    {
      "layer_id": 3,
      "neurons": 32,
      "activation": "Sigmoid",
      "connections": ["HIDDEN_2", "OUTPUT"]
    }
  ],
  "training_data": {
    "epochs": 0,
    "accuracy": 0.0,
    "loss": 1.0
  },
  "connections": {
    "ai_core": "C:\\AI\\Agents\\AgentName",
    "gene1799": "D:\\Gene1799\\Agents\\AgentName",
    "electronic": "D:\\Electronic\\Agents\\AgentName"
  }
}
```

---

## 🧠 Training Sinaptico

### Addestrare un Agente

```powershell
# Addestra con 100 epochs (default)
.\gene1799_neural_hub.ps1 -Mode TRAIN -AgentName "VisionClassifier"

# Output esempio:
# ╔═══════════════════════════════════════════════════════════╗
# ║           🧠 SYNAPTIC TRAINING INITIATED 🧠               ║
# ╚═══════════════════════════════════════════════════════════╝
# 
# Training Progress:
# ══════════════════════════════════════════════════════════
# Epoch 10/100 | Loss: 0.9234 | Accuracy: 8.45% | Progress: 10%
# Epoch 20/100 | Loss: 0.8156 | Accuracy: 18.32% | Progress: 20%
# ...
# Epoch 100/100 | Loss: 0.0523 | Accuracy: 95.67% | Progress: 100%
# 
# ══════════════════════════════════════════════════════════
# ✅ Training complete!
#    Final Accuracy: 95.67%
#    Final Loss: 0.0523
```

### Parametri di Training

Il sistema salva automaticamente:
- **Pesi sinaptici** in `D:\Gene1799\Synaptic\Weights\{AgentName}\weights_epoch_{N}.json`
- **Metriche** di accuracy e loss
- **Timestamp** di training
- **Configurazione layers**

---

## 📊 Monitoraggio Sistema

### Stato Corrente

```powershell
.\gene1799_neural_hub.ps1 -Mode STATUS
```

Output:
```
╔═══════════════════════════════════════════════════════════╗
║              📊 NEURAL HUB STATUS REPORT 📊               ║
╚═══════════════════════════════════════════════════════════╝

🔗 System Connections:
══════════════════════════════════════════════════════════
  AI Core: ✓ ONLINE
  GENE1799 Core: ✓ ONLINE
  Electronic Systems: ✓ ONLINE

🤖 Registered Agents:
══════════════════════════════════════════════════════════

  Agent: VisionClassifier
    Type: CLASSIFIER
    Status: TRAINED
    Accuracy: 95.67%
    Synaptic Layers: 3

  Agent: DataPredictor
    Type: PREDICTOR
    Status: INITIALIZED
    Accuracy: 0%
    Synaptic Layers: 3

🧠 Synaptic Network:
══════════════════════════════════════════════════════════
  Total Nodes: 3
  Total Connections: 6
  Status: ACTIVE
```

### Visualizza Log

```powershell
# Ultimi 50 log
Get-Content "D:\Gene1799\Logs\neural_hub.log" -Tail 50

# Solo errori
Get-Content "D:\Gene1799\Logs\neural_hub.log" | Select-String "\[ERROR\]"

# Solo eventi sinaptici
Get-Content "D:\Gene1799\Logs\neural_hub.log" | Select-String "\[SYNAPTIC\]"
```

---

## 🔧 Configurazione Avanzata

### Personalizzare la Rete Sinaptica

Modifica il file `D:\Gene1799\Synaptic\connection_map.json`:

```json
{
  "C:\\AI": {
    "connected_to": ["D:\\Gene1799\\Modules", "D:\\Electronic\\Modules"],
    "purpose": "AI Core processing and model inference",
    "synaptic_weight": 1.0
  },
  "D:\\Gene1799": {
    "connected_to": ["C:\\AI", "D:\\Electronic"],
    "purpose": "Central hub and agent coordination",
    "synaptic_weight": 1.0
  },
  "D:\\Electronic": {
    "connected_to": ["C:\\AI", "D:\\Gene1799"],
    "purpose": "Electronic systems integration",
    "synaptic_weight": 0.8
  }
}
```

### Accesso Diretto agli Agenti

Ogni agente ha il proprio script di controllo:

```powershell
cd D:\Gene1799\Agents\VisionClassifier

# Info agente
.\agent.ps1 -Action INFO

# Attiva agente
.\agent.ps1 -Action ACTIVATE

# Train agente
.\agent.ps1 -Action TRAIN
```

---

## 🎯 Esempi Pratici

### Esempio 1: Classificatore di Immagini

```powershell
# 1. Crea l'agente
.\gene1799_neural_hub.ps1 -Mode ADD_AGENT `
    -AgentName "ImageClassifier" `
    -AgentType "CLASSIFIER"

# 2. Addestra (simula training su dataset immagini)
.\gene1799_neural_hub.ps1 -Mode TRAIN `
    -AgentName "ImageClassifier"

# 3. Verifica lo stato
.\gene1799_neural_hub.ps1 -Mode STATUS
```

### Esempio 2: Predittore di Serie Temporali

```powershell
# 1. Crea l'agente
.\gene1799_neural_hub.ps1 -Mode ADD_AGENT `
    -AgentName "TimeSeriesPredictor" `
    -AgentType "PREDICTOR"

# 2. Addestra
.\gene1799_neural_hub.ps1 -Mode TRAIN `
    -AgentName "TimeSeriesPredictor"
```

### Esempio 3: Generatore di Contenuti

```powershell
# 1. Crea l'agente
.\gene1799_neural_hub.ps1 -Mode ADD_AGENT `
    -AgentName "ContentGenerator" `
    -AgentType "GENERATOR"

# 2. Addestra
.\gene1799_neural_hub.ps1 -Mode TRAIN `
    -AgentName "ContentGenerator"
```

---

## 📁 Struttura File e Directory

### Directory Principali

```
C:\AI\
├── Models\           # Modelli AI pre-addestrati
├── Agents\           # Deployment agenti AI
│   └── {AgentName}\  # Cartella specifica per agente
└── Temp\             # File temporanei

D:\Gene1799\
├── Explorer\         # Script di gestione
│   ├── gene1799_neural_hub.ps1
│   ├── gene1799_gui.ps1
│   └── hub_explorer_FIXED.ps1
├── Modules\          # Moduli condivisi
├── Agents\           # Configurazioni agenti
│   └── {AgentName}\
│       ├── config.json
│       └── agent.ps1
├── Synaptic\         # Rete sinaptica
│   ├── Weights\      # Pesi salvati
│   │   └── {AgentName}\
│   │       └── weights_epoch_{N}.json
│   └── connection_map.json
├── Database\         # Database agenti
│   └── agents.json
└── Logs\             # Log di sistema
    └── neural_hub.log

D:\Electronic\
├── Modules\          # Moduli elettronici
├── Data\             # Dati sensori/hardware
└── Agents\           # Agenti per controllo hardware
```

### File Importanti

| File | Descrizione |
|------|-------------|
| `agents.json` | Database centrale degli agenti |
| `connection_map.json` | Mappa connessioni sinaptiche |
| `neural_hub.log` | Log completo del sistema |
| `config.json` | Configurazione specifica agente |
| `weights_epoch_{N}.json` | Pesi sinaptici salvati |

---

## 🛠️ Troubleshooting

### Problema: "Script non riconosciuto"

```powershell
# Soluzione
Set-ExecutionPolicy Bypass -Scope Process -Force
Unblock-File .\gene1799_neural_hub.ps1
```

### Problema: "Directory non trovata"

```powershell
# Reinizializza il sistema
.\gene1799_neural_hub.ps1 -Mode INIT
```

### Problema: "Agent già esistente"

```powershell
# Verifica agenti registrati
.\gene1799_neural_hub.ps1 -Mode STATUS

# Modifica il database se necessario
notepad D:\Gene1799\Database\agents.json
```

### Problema: Training fallisce

```powershell
# Controlla i log
Get-Content "D:\Gene1799\Logs\neural_hub.log" -Tail 30

# Verifica che l'agente esista
Test-Path "D:\Gene1799\Agents\{AgentName}\config.json"
```

---

## 🔐 Sicurezza e Best Practices

### Backup

```powershell
# Backup database agenti
Copy-Item "D:\Gene1799\Database\agents.json" `
          "D:\Gene1799\Database\agents.json.backup_$(Get-Date -Format 'yyyyMMdd')"

# Backup pesi sinaptici
Copy-Item "D:\Gene1799\Synaptic\Weights" `
          "D:\Gene1799\Synaptic\Weights_Backup_$(Get-Date -Format 'yyyyMMdd')" `
          -Recurse
```

### Monitoraggio

```powershell
# Controlla spazio disco
Get-PSDrive C,D | Select-Object Name, Used, Free

# Conta agenti
(Get-Content "D:\Gene1799\Database\agents.json" | ConvertFrom-Json).agents.Count

# Statistiche training
$db = Get-Content "D:\Gene1799\Database\agents.json" | ConvertFrom-Json
$db.agents | Select-Object name, @{N='Accuracy';E={$_.training_data.accuracy}}
```

---

## 📈 Roadmap Futura

- [ ] **Interfaccia Web**: Dashboard web per gestione remota
- [ ] **API REST**: Endpoints per integrazione esterna
- [ ] **Distributed Training**: Training distribuito su più nodi
- [ ] **Auto-scaling**: Aggiunta automatica di neuroni/layer
- [ ] **Transfer Learning**: Condivisione pesi tra agenti
- [ ] **Real-time Monitoring**: Dashboard live delle metriche
- [ ] **Hardware Integration**: Connessione diretta con sensori/attuatori
- [ ] **Cloud Sync**: Sincronizzazione con cloud storage

---

## 🎓 Comandi Rapidi di Riferimento

```powershell
# Setup iniziale
.\gene1799_neural_hub.ps1 -Mode INIT

# Aggiungi agente
.\gene1799_neural_hub.ps1 -Mode ADD_AGENT -AgentName "MyAgent" -AgentType "CLASSIFIER"

# Addestra agente
.\gene1799_neural_hub.ps1 -Mode TRAIN -AgentName "MyAgent"

# Stato sistema
.\gene1799_neural_hub.ps1 -Mode STATUS

# GUI
.\gene1799_gui.ps1

# Log recenti
Get-Content "D:\Gene1799\Logs\neural_hub.log" -Tail 20

# Info agente specifico
cd D:\Gene1799\Agents\MyAgent
.\agent.ps1 -Action INFO
```

---

## 📞 Supporto

Per problemi o domande:

1. Controlla i log: `D:\Gene1799\Logs\neural_hub.log`
2. Verifica lo stato: `.\gene1799_neural_hub.ps1 -Mode STATUS`
3. Consulta questa guida per soluzioni comuni

---

*Documento creato il: 03/02/2026*  
*Versione Sistema: 1.0*  
*GENE1799 Neural Hub - Synaptic Agent System*
