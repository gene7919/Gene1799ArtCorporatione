# 🎨 Gene1799 Art Corporation - Neural Dashboard
## Guida Completa di Utilizzo

---

## 📋 Indice

1. [Setup Iniziale](#setup-iniziale)
2. [Avvio del Dashboard](#avvio-del-dashboard)
3. [Interfaccia Utente](#interfaccia-utente)
4. [Controllo degli Agenti](#controllo-degli-agenti)
5. [Monitoraggio e Metriche](#monitoraggio-e-metriche)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Setup Iniziale

### Prerequisiti
- PowerShell 5.0 o superiore
- Windows 10/11
- Spazio su disco: almeno 500MB
- Struttura directory: `D:\Gene1799\`, `D:\Electronic\`

### Step 1: Inizializzazione del Dashboard

```powershell
# Accedi come amministratore
cd D:\Gene1799
.\gene1799_dashboard_integration.ps1 -Mode SETUP
```

**Output Atteso:**
```
╔═══════════════════════════════════════════════════════════╗
║     🎨 GENE1799 DASHBOARD INITIALIZATION 🎨              ║
╚═══════════════════════════════════════════════════════════╝

✅ Dashboard initialized successfully!
```

Questo comando:
- ✓ Crea la struttura directory necessaria
- ✓ Genera i 4 agenti predefiniti
- ✓ Configura il database
- ✓ Inizializza i log

### Step 2: Creazione degli Agenti Predefiniti

L'inizializzazione crea automaticamente 4 agenti AI:

| Nome Agente | Tipo | Descrizione | Accuracy |
|---|---|---|---|
| **ArtAnalyzer** | ART_CLASSIFIER | Analizza e classifica le opere | 92.5% |
| **ArtworkManager** | ASSET_MANAGER | Gestisce l'inventario | 88.3% |
| **QualityAssessor** | QUALITY_EVALUATOR | Valuta autenticità | 78.9% |
| **CuratorAI** | RECOMMENDATION_ENGINE | Consigli ai collezionisti | 95.2% |

---

## 🌐 Avvio del Dashboard

### Metodo 1: Web Server PowerShell (Consigliato)

```powershell
# Terminal 1: Avvia il web server
.\gene1799_dashboard_integration.ps1 -Mode WEB -DashboardPort 8080

# Il terminal mostrerà:
# ✅ Dashboard available at: http://localhost:8080
```

Poi apri il browser a: **http://localhost:8080**

### Metodo 2: Apertura Diretta del File HTML

```powershell
# Apri direttamente il file
Invoke-Item "D:\Electronic\Dashboard\Web\index.html"
```

### Metodo 3: Avvio con IIS Express (Alternativo)

```powershell
# Se IIS Express è installato
iisexpress /path:D:\Electronic\Dashboard\Web /port:8080
```

---

## 🎮 Interfaccia Utente

### Layout Principale

```
┌─────────────────────────────────────────────────────────┐
│ 🧠 GENE1799 NEURAL DASHBOARD          [ONLINE] ●●●      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ⚙️ CONTROL CENTER                                      │
│  ├─ Agent Name: [____________]                          │
│  ├─ Agent Type: [Dropdown ▼]                            │
│  ├─ Training Epochs: [300]                              │
│  ├─ Learning Rate: [0.005]                              │
│  └─ [Create] [Train] [Activate] [Refresh]              │
│                                                           │
├─────────────────────────────────────────────────────────┤
│  📊 METRICS OVERVIEW                                    │
│  ├─ Total Agents: 4  │ Active: 3  │ Avg Acc: 88.5%    │
│  └─ System Health: 100%                                 │
│                                                           │
├─────────────────────────────────────────────────────────┤
│  🔗 SYNAPTIC NETWORK TOPOLOGY                          │
│  [Network Visualization - Live Animation]              │
│                                                           │
├─────────────────────────────────────────────────────────┤
│  🤖 ACTIVE AGENTS (Cards Grid)                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ Agent 1  │ │ Agent 2  │ │ Agent 3  │ │ Agent 4  │  │
│  │ [Card]   │ │ [Card]   │ │ [Card]   │ │ [Card]   │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│                                                           │
├─────────────────────────────────────────────────────────┤
│  📋 SYSTEM LOGS (Real-time updates)                    │
│  [System initialized]                                    │
│  [Agent 'ArtAnalyzer' activated]                        │
│  [Training epoch 50/300 - Accuracy: 45.23%]            │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### Sezioni Principali

#### 1. **Header (Intestazione)**
- Mostra lo stato del sistema (ONLINE/OFFLINE)
- Pulse animato per il collegamento attivo
- Nome e versione del sistema

#### 2. **Control Center (Centro di Controllo)**
```
Input Fields:
├─ Agent Name: Nome dell'agente da creare/allenare
├─ Agent Type: Tipo di agente (Dropdown)
├─ Training Epochs: Numero di iterazioni di training
└─ Learning Rate: Velocità di apprendimento (0.0001 - 0.1)

Pulsanti:
├─ [Create Agent]: Crea un nuovo agente
├─ [Start Training]: Inizia l'allenamento
├─ [Activate All]: Attiva tutti gli agenti
└─ [Refresh]: Aggiorna il dashboard
```

#### 3. **Metrics Overview (Panoramica Metriche)**
```
Total Agents:    Numero totale di agenti registrati
Active Agents:   Agenti attualmente attivi
Avg Accuracy:    Accuratezza media di tutti gli agenti
System Health:   Percentuale di salute del sistema (0-100%)
```

#### 4. **Synaptic Network Topology (Visualizzazione Rete)**
- Mostra i nodi principali:
  - AI Core (C:\AI)
  - GENE1799 Core (D:\Gene1799)
  - Electronic Systems (D:\Electronic)
  - Dashboard (D:\Electronic\Dashboard)
- Animazione in tempo reale delle connessioni
- Update automatico ogni 100ms

#### 5. **Active Agents (Agenti Attivi)**
Card per ogni agente con:
- Nome e Tipo
- Status (ACTIVE/TRAINING/INITIALIZED)
- Accuracy (progress bar)
- Epochs completati
- Layers sinaptici
- Configurazione rete neurale

#### 6. **System Logs (Log di Sistema)**
- Real-time updates dei comandi eseguiti
- Colori differenti per tipo:
  - 🟢 SUCCESS (Verde)
  - 🔴 ERROR (Rosso)
  - 🟠 WARNING (Arancione)
  - 🔵 INFO (Azzurro)
- Storico dei 50 log più recenti

---

## 🤖 Controllo degli Agenti

### Creazione di un Nuovo Agente

1. **Nel Control Center:**
   - Inserisci il nome: `MyCustomAgent`
   - Seleziona il tipo: `ART_CLASSIFIER`
   - Clicca `[Create Agent]`

2. **Output nel Log:**
   ```
   [14:32:15] [SUCCESS] Agent "MyCustomAgent" created successfully
   ```

3. **Verificazione:**
   - Nuovo card apparirà nella griglia
   - Status: `INITIALIZED`
   - Accuracy: `0%`

### Allenamento di un Agente

1. **Nel Control Center:**
   - Agent Name: `ArtAnalyzer`
   - Training Epochs: `500`
   - Learning Rate: `0.005`
   - Clicca `[Start Training]`

2. **Durante il Training:**
   ```
   Epoch 50/500 | Loss: 0.7821 | Accuracy: 45.23% | Progress: 10%
   Epoch 100/500 | Loss: 0.4532 | Accuracy: 67.45% | Progress: 20%
   ...
   ```

3. **Completamento:**
   ```
   [Training complete for "ArtAnalyzer" - Final Accuracy: 92.34%]
   ```

### Attivazione di Agenti

```powershell
# Via Dashboard:
# Clicca [Activate All]

# Oppure via PowerShell:
# Dopo l'allenamento, gli agenti passano a ACTIVE automaticamente
```

### Monitoraggio Agenti

Ogni card mostra in tempo reale:
- **Status Badge**: ACTIVE (🟢), TRAINING (🟡), INITIALIZED (⚪)
- **Accuracy Bar**: Visualizzazione grafica (0-100%)
- **Synaptic Layers**: Numero di layer (solitamente 3)
- **Network Config**: 128 → 64 → 32 neuroni

---

## 📊 Monitoraggio e Metriche

### Raccolta Metriche (Via PowerShell)

```powershell
# Raccogli metriche di sistema
.\gene1799_dashboard_integration.ps1 -Mode METRICS
```

**Output:**
```
📊 Metrics collected: 4 agents, Avg Accuracy: 88.68%
```

### Report di Stato

```powershell
# Visualizza report completo
.\gene1799_dashboard_integration.ps1 -Mode STATUS
```

**Output Completo:**
```
╔═══════════════════════════════════════════════════════════╗
║       📊 DASHBOARD STATUS REPORT 📊                      ║
╚═══════════════════════════════════════════════════════════╝

🎨 Dashboard Configuration:
══════════════════════════════════════════════════════════
  Root Directory: D:\Electronic\Dashboard
  Web Root: D:\Electronic\Dashboard\Web
  Port: 8080

🤖 Registered Agents:
══════════════════════════════════════════════════════════

  📌 ArtAnalyzer
     Type: ART_CLASSIFIER
     Status: ACTIVE
     Accuracy: 92.5%
     Training Epochs: 300

  📌 ArtworkManager
     Type: ASSET_MANAGER
     Status: ACTIVE
     Accuracy: 88.3%
     Training Epochs: 200

  [... altri agenti ...]

📈 System Metrics:
══════════════════════════════════════════════════════════
  Total Agents: 4
  Active Agents: 4
  Average Accuracy: 88.68%
  System Status: OPERATIONAL
```

### File di Log

Percorso: `D:\Electronic\Dashboard\Logs\`

- `dashboard.log` - Log principale
- `metrics_YYYY-MM-DD_HH-MM-SS.json` - Snapshot metriche

Esempio di metrica salvata:
```json
{
  "timestamp": "2025-02-04 14:32:15",
  "total_agents": 4,
  "active_agents": 4,
  "avg_accuracy": 88.68,
  "system_health": "OPERATIONAL",
  "trained_agents": 4,
  "agents": [
    {
      "name": "ArtAnalyzer",
      "type": "ART_CLASSIFIER",
      "status": "ACTIVE",
      "accuracy": 92.5,
      "training_epochs": 300
    },
    ...
  ]
}
```

---

## 🎨 Tema e Personalizzazione

### Colori Disponibili

| Nome | Codice | Uso |
|------|--------|-----|
| Primary | `#00ff88` | Elementi principali |
| Secondary | `#ff00ff` | Control panel |
| Accent | `#00d4ff` | Accenti |
| Success | `#00ff88` | Messaggi positivi |
| Warning | `#ffa500` | Avvisi |
| Danger | `#ff1744` | Errori |

### Font Utilizzati

- **Orbitron**: Titoli futuristici (Interfaccia)
- **Space Mono**: Corpo testo monospazio (Dati)
- **Playfair Display**: Titoli eleganti (Rapporti)

---

## 💻 Workflow Completo - Esempio Pratico

### Scenario: Creare e Addestrare un Nuovo Agente

#### Step 1: Inizializzazione
```powershell
cd D:\Gene1799
.\gene1799_dashboard_integration.ps1 -Mode SETUP
```

#### Step 2: Avvio Web Server
```powershell
.\gene1799_dashboard_integration.ps1 -Mode WEB -DashboardPort 8080
# Output: ✅ Dashboard available at: http://localhost:8080
```

#### Step 3: Apertura Dashboard
- Apri browser: `http://localhost:8080`
- Visualizza 4 agenti predefiniti

#### Step 4: Creazione Nuovo Agente
```
Control Center:
├─ Agent Name: "ImageClassifier"
├─ Agent Type: "ART_CLASSIFIER"
└─ Click [Create Agent]

Log Output:
[Agent "ImageClassifier" created successfully]
```

#### Step 5: Allenamento
```
Control Center:
├─ Agent Name: "ImageClassifier"
├─ Training Epochs: 400
├─ Learning Rate: 0.008
└─ Click [Start Training]

Progress:
├─ Epoch 50/400: Loss: 0.632, Accuracy: 52.34%
├─ Epoch 100/400: Loss: 0.445, Accuracy: 68.92%
├─ Epoch 200/400: Loss: 0.234, Accuracy: 82.56%
├─ Epoch 400/400: Loss: 0.087, Accuracy: 94.23%
└─ ✅ Training complete
```

#### Step 6: Attivazione
```
Click [Activate All]
✅ All trainable agents activated
```

#### Step 7: Verifica Metriche
```powershell
.\gene1799_dashboard_integration.ps1 -Mode STATUS

📊 Total Agents: 5
   Active Agents: 5
   Avg Accuracy: 90.76%
```

---

## 🐛 Troubleshooting

### Problema: Dashboard non carica

**Causa:** Port 8080 occupata
```powershell
# Soluzione: Usa porta diversa
.\gene1799_dashboard_integration.ps1 -Mode WEB -DashboardPort 8090
```

### Problema: Agenti non appaiono

**Causa:** Directory di agent non creata
```powershell
# Verifica:
Test-Path "D:\Electronic\Dashboard\Agents\Active"

# Crea manualmente:
New-Item -Path "D:\Electronic\Dashboard\Agents\Active" -ItemType Directory -Force
```

### Problema: Training non inizia

**Causa:** File config.json mancante
```powershell
# Controlla:
Get-ChildItem -Path "D:\Electronic\Dashboard\Agents\Active" -Recurse

# Reinizializza:
.\gene1799_dashboard_integration.ps1 -Mode SETUP
```

### Problema: Metriche non si aggiornano

**Soluzione:**
1. Clicca `[Refresh]` nel Control Center
2. Oppure attendi 5 secondi (auto-refresh)
3. Controlla logs: `D:\Electronic\Dashboard\Logs\dashboard.log`

### Problema: Accesso negato

**Causa:** Permessi insufficienti
```powershell
# Soluzione: Avvia PowerShell come Amministratore
# Oppure:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📈 Performance Tips

### Ottimizzazione

1. **Refresh Rate**: Auto-refresh ogni 5 secondi
   - Modificabile nel codice JavaScript

2. **Log Limit**: Massimo 50 log visualizzati
   - Evita lag su log molto lunghi

3. **Network Visualization**: Update ogni 100ms
   - Disabilitabile per performance bassa

### Monitoraggio Memoria

```powershell
# Controlla utilizzo processo PowerShell
Get-Process powershell | Select-Object Name, WorkingSet
```

---

## 📞 Supporto e Contatti

### Documentazione
- PowerShell Docs: `gene1799_dashboard_integration.ps1`
- HTML Docs: `gene1799_dashboard.html`
- Log Files: `D:\Electronic\Dashboard\Logs\`

### Debug Mode

```powershell
# Attiva verbose output
$VerbosePreference = "Continue"
.\gene1799_dashboard_integration.ps1 -Mode SETUP
```

---

## 🎯 Prossimi Passi

1. **Integrazione API**: Collegare a database esterno
2. **Machine Learning**: Implementare veri modelli ML
3. **Real-time Sync**: WebSocket per live updates
4. **Mobile App**: Versione mobile del dashboard
5. **Advanced Analytics**: Grafici più complessi

---

**Gene1799 Art Corporation - Neural Dashboard v1.0**
*Ultima modifica: 2025-02-04*
