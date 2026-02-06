# GENE1799 - RISOLUZIONE COMPLETA PROBLEMI
**Data**: 2026-02-02  
**Stato**: Fix avanzato pronto

---

## 🔴 PROBLEMI IDENTIFICATI

### PROBLEMA 1: Bug op_Addition (CRITICO - 181 occorrenze)
**Errore**: `InvalidOperation: Method invocation failed because [System.Management.Automation.PSObject] does not contain a method named 'op_Addition'`

**Causa**: Nel file `Gene1799AgentScanner.psm1` la riga:
```powershell
$registeredCount = $registeredCount + 1
```

PowerShell interpreta `$registeredCount` come PSObject invece di integer.

**Soluzione**: Forzare il cast a [int]:
```powershell
[int]$registeredCount = [int]$registeredCount + 1
```

### PROBLEMA 2: Python PATH non configurato
**Errore**: `Python non trovato in C:\Python312`

**Causa**: Python non installato in C:\Python312 o non nel PATH

**Soluzione**: 
1. Trova Python con `where.exe python`
2. Aggiungi al PATH: `$env:PATH += ";C:\Path\To\Python;C:\Path\To\Python\Scripts"`

### PROBLEMA 3: Dashboard Port Conflict (Porta 18002)
**Errore**: `Failed to listen on prefix 'http://localhost:18002/' because it conflicts with an existing registration`

**Causa**: Processo System (PID 4) occupa la porta

**Soluzione**: Usa porta alternativa
```powershell
Start-Gene1799Orchestrator -DashboardPort 18003
```

### PROBLEMA 4: Modulo Gene1799Bus non trovato
**Errore**: `The specified module 'D:\Gene1799\modules\Gene1799Bus\Gene1799Bus.psd1' was not loaded`

**Causa**: File .psd1 mancante o path errato

**Soluzione**: Verifica esistenza file o salta il caricamento

---

## ✅ SOLUZIONI AUTOMATICHE

### OPZIONE A: Script Completo (CONSIGLIATO)
Esegui lo script completo che risolve tutti i problemi:

```powershell
# Scarica ed esegui
.\Gene1799_CompleteFixScript.ps1
```

**Features**:
- ✅ Fix automatico op_Addition con multiple strategie
- ✅ Discovery automatica Python in tutte le locazioni standard
- ✅ Gestione intelligente porta Dashboard
- ✅ Reload moduli con validazione
- ✅ Startup sistema con error handling
- ✅ Test suite completa per verificare tutti i fix

### OPZIONE B: Patch Diretta Solo op_Addition
Se vuoi fixare solo il bug op_Addition:

```powershell
# Esegui solo la patch
.\Gene1799_DirectPatch_AgentScanner.ps1
```

Poi ricarica il modulo:
```powershell
Import-Module 'D:\Gene1799\modules\Gene1799AgentScanner\Gene1799AgentScanner.psd1' -Force
```

---

## 🛠️ SOLUZIONE MANUALE

Se gli script automatici non funzionano, segui questi passi:

### STEP 1: Fix manuale op_Addition

1. **Apri il file**:
   ```
   D:\Gene1799\modules\Gene1799AgentScanner\Gene1799AgentScanner.psm1
   ```

2. **Cerca** tutte le righe contenenti:
   ```powershell
   $registeredCount = $registeredCount + 1
   ```

3. **Sostituisci** con:
   ```powershell
   [int]$registeredCount = [int]$registeredCount + 1
   ```

4. **Salva** il file

5. **Ricarica** il modulo:
   ```powershell
   Import-Module 'D:\Gene1799\modules\Gene1799AgentScanner\Gene1799AgentScanner.psd1' -Force
   ```

### STEP 2: Configura Python PATH

1. **Trova Python**:
   ```powershell
   where.exe python
   ```

2. **Aggiungi al PATH** (esempio con Python in C:\Python312):
   ```powershell
   $env:PATH += ";C:\Python312;C:\Python312\Scripts"
   ```

3. **Verifica**:
   ```powershell
   python --version
   ```

### STEP 3: Usa porta alternativa per Dashboard

Invece di porta 18002, usa:
```powershell
Start-Gene1799Orchestrator -ScanAndRegister -StartDashboard -DashboardPort 18003
```

### STEP 4: Avvia il sistema

```powershell
# Core
Start-Gene1799Core -Root 'D:\Gene1799' -LoadAgents

# Orchestrator (porta 18003 per evitare conflitti)
Start-Gene1799Orchestrator -ScanAndRegister -StartDashboard -DashboardPort 18003

# Auto-Learning (con parametri corretti)
Start-GeneAutoLearning -BusRoot "D:\Gene1799" -SystemId "Gene1799Hub"
```

---

## 🧪 VERIFICA FINALE

Dopo aver applicato i fix, esegui questi test:

### TEST 1: Nessun errore op_Addition
```powershell
Invoke-Gene1799AgentScan -AutoRegister
```
**Risultato atteso**: Nessun messaggio "InvalidOperation: op_Addition"

### TEST 2: Python funzionante
```powershell
python --version
```
**Risultato atteso**: Versione Python visualizzata

### TEST 3: Auto-Learning attivo
```powershell
Get-GeneAutoLearningStatus
```
**Risultato atteso**: Status "RUNNING" per Gene1799Hub

### TEST 4: Dashboard accessibile
```powershell
Start-Process "http://localhost:18003/"
```
**Risultato atteso**: Dashboard si apre nel browser

### TEST 5: Agenti registrati
```powershell
Get-Gene1799RegisteredAgents
```
**Risultato atteso**: Lista di 181 agenti registrati

### TEST 6: Esecuzione agente
```powershell
Invoke-Gene1799Agent -AgentName "agent_example_ai" -Arguments @{Message = "Test"}
```
**Risultato atteso**: Output JSON dell'agente

---

## 📊 COMANDI UTILI

### Stato Sistema
```powershell
Get-Gene1799Status
```

### Statistiche Bus (con parametri corretti)
```powershell
Get-GeneBusStats -BusRoot "D:\Gene1799" -SystemId "Gene1799Hub"
```

### Knowledge Base
```powershell
# Visualizza
Get-GeneKnowledge -BusRoot "D:\Gene1799" -Topic "AI"

# Aggiungi
Add-GeneKnowledge -BusRoot "D:\Gene1799" -Topic "SemanticKernel" -Content "Framework integrato"
```

### Restart completo
```powershell
# Stop
Stop-GeneAutoLearning -SystemId "Gene1799Hub"

# Ricarica moduli
Import-Module 'D:\Gene1799\modules\Gene1799Core\Gene1799Core.psd1' -Force
Import-Module 'D:\Gene1799\modules\Gene1799Orchestrator\Gene1799Orchestrator.psd1' -Force
Import-Module 'D:\Gene1799\modules\Gene1799AgentScanner\Gene1799AgentScanner.psd1' -Force

# Start
Start-Gene1799Core -Root 'D:\Gene1799' -LoadAgents
Start-Gene1799Orchestrator -ScanAndRegister -StartDashboard -DashboardPort 18003
Start-GeneAutoLearning -BusRoot "D:\Gene1799" -SystemId "Gene1799Hub"
```

---

## 🔍 DIAGNOSTICA AVANZATA

### Verifica file AgentScanner
```powershell
$scannerPath = "D:\Gene1799\modules\Gene1799AgentScanner\Gene1799AgentScanner.psm1"
Select-String -Path $scannerPath -Pattern "registeredCount" | Select-Object LineNumber, Line
```

### Trova processi su porte
```powershell
Get-NetTCPConnection -LocalPort 18002,18003,18004 | 
    ForEach-Object { 
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Port = $_.LocalPort
            ProcessName = $proc.Name
            PID = $_.OwningProcess
        }
    }
```

### Verifica moduli caricati
```powershell
Get-Module Gene1799* | Select-Object Name, Version, Path
```

---

## 📝 NOTE IMPORTANTI

1. **Backup automatico**: Gli script creano backup automatici con timestamp prima di modificare i file

2. **Porta alternativa**: Se la porta 18002 è occupata dal sistema, usa 18003 o 18004

3. **Python PATH**: Il PATH configurato con `$env:PATH` è temporaneo (solo sessione corrente). Per renderlo permanente, aggiungi al PATH di sistema

4. **GeneBus parametri**: Tutti i comandi GeneBus richiedono `-BusRoot` e spesso `-SystemId`

5. **Module reload**: Dopo modifiche ai file .psm1, ricarica sempre con `-Force`

---

## ✅ CHECKLIST FINALE

- [ ] op_Addition bug fixato (0 errori durante scan)
- [ ] Python trovato e nel PATH
- [ ] Dashboard accessibile (porta 18003)
- [ ] Auto-Learning in stato RUNNING
- [ ] 181 agenti registrati
- [ ] Esecuzione agente funzionante
- [ ] Tutti i moduli caricati correttamente

---

**Versione documento**: 1.0  
**Ultima modifica**: 2026-02-02 23:16
