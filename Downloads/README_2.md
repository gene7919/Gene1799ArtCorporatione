# 🔧 GENE1799 REPAIR TOOLKIT

## 📋 Panoramica

Questo toolkit contiene 3 script PowerShell per risolvere completamente i problemi del sistema GENE1799:

1. **master_repair.ps1** - Script principale che esegue tutto automaticamente
2. **diagnose_and_fix.ps1** - Diagnostica e corregge hub_explorer.ps1
3. **cleanup_logs.ps1** - Pulisce e archivia i log

---

## 🚀 SOLUZIONE RAPIDA (CONSIGLIATA)

### Opzione 1: Esecuzione Automatica Completa

```powershell
# 1. Apri PowerShell come amministratore
# 2. Naviga nella cartella D:\Gene1799\Explorer
cd D:\Gene1799\Explorer

# 3. Copia master_repair.ps1 nella cartella
# (Scarica il file e copialo in D:\Gene1799\Explorer)

# 4. Esegui lo script master
Set-ExecutionPolicy Bypass -Scope Process -Force
.\master_repair.ps1
```

**Cosa fa master_repair.ps1:**
- ✅ Archivia e pulisce i log pieni di errori
- ✅ Crea un backup del vecchio hub_explorer.ps1
- ✅ Genera un nuovo hub_explorer.ps1 corretto
- ✅ Valida la sintassi PowerShell
- ✅ Esegue test automatici in modalità DRYRUN e LIVE
- ✅ Mostra i risultati e i log recenti

---

## 🔍 DETTAGLIO DEI PROBLEMI RISOLTI

### Problema 1: Errore di Sintassi
```
ParserError: D:\Gene1799\Explorer\hub_explorer.ps1:56
Line |
  56 |  }
     |  ~
     | Unexpected token '}' in expression or statement.
```

**Causa:** Parentesi graffa chiusa senza corrispondente apertura o struttura malformata.

**Soluzione:** `master_repair.ps1` riscrive completamente lo script con sintassi corretta.

---

### Problema 2: Log Pieno di Errori
```
[ERROR] Safe-Action chiamata con parametri vuoti: From='', To='D:\Gene1799\Config\'
[ERROR] Safe-Action chiamata con parametri vuoti: From='', To='D:\Gene1799\Config\'
...
```

**Causa:** La funzione Safe-Action veniva chiamata con parametri `$From` vuoti.

**Soluzione:** 
- `cleanup_logs.ps1` archivia il vecchio log
- Nuovo `hub_explorer.ps1` valida i parametri prima dell'uso
- Messaggi di errore più chiari e informativi

---

## 📁 STRUTTURA FILE CORRETTA

Dopo l'esecuzione di `master_repair.ps1`, avrai:

```
D:\Gene1799\
├── Explorer\
│   ├── hub_explorer.ps1                    ← Script corretto e funzionante
│   ├── hub_explorer.ps1.backup_*          ← Backup automatico del vecchio
│   └── test_runner.ps1                    ← Script helper per test rapidi
├── Exp\                                    ← Directory sorgente
├── Modules\                                ← Directory destinazione
├── Config\
└── Logs\
    └── master_orchestrator.log             ← Log pulito e nuovo

E:\Gene1799_Data\
└── Logs_Archive\
    └── master_orchestrator_*.log           ← Vecchi log archiviati
```

---

## 🛠️ UTILIZZO DEGLI SCRIPT INDIVIDUALI

### Script 1: master_repair.ps1 (TUTTO IN UNO)
```powershell
cd D:\Gene1799\Explorer
.\master_repair.ps1
```

### Script 2: diagnose_and_fix.ps1 (Solo Diagnostica e Fix)
```powershell
cd D:\Gene1799\Explorer
.\diagnose_and_fix.ps1
```

### Script 3: cleanup_logs.ps1 (Solo Pulizia Log)
```powershell
cd D:\Gene1799\Explorer
.\cleanup_logs.ps1
```

---

## 🎯 UTILIZZO DEL HUB_EXPLORER.PS1 CORRETTO

Dopo la riparazione, usa `hub_explorer.ps1` così:

### Modalità DRYRUN (test senza modifiche)
```powershell
.\hub_explorer.ps1 -Mode DRYRUN -From "D:\Gene1799\Exp" -To "D:\Gene1799\Modules"
```

### Modalità LIVE (esecuzione reale)
```powershell
.\hub_explorer.ps1 -Mode LIVE -From "D:\Gene1799\Exp" -To "D:\Gene1799\Modules"
```

### Parametri Predefiniti
Se non specifichi parametri, usa i valori di default:
```powershell
.\hub_explorer.ps1    # Equivale a: -Mode DRYRUN -From "D:\Gene1799\Exp" -To "D:\Gene1799\Modules"
```

---

## 📊 FUNZIONALITÀ DEL NUOVO hub_explorer.ps1

### ✅ Validazione Parametri
- Controlla che `$From` e `$To` non siano vuoti
- Verifica che il path sorgente esista
- Crea automaticamente il path di destinazione se mancante

### 📝 Logging Migliorato
- Timestamp per ogni operazione
- Livelli di log: INFO, WARN, ERROR, SUCCESS
- Log directory creata automaticamente se mancante

### 🛡️ Gestione Errori
- Try-catch per operazioni di copia
- Messaggi di errore dettagliati
- Return anticipato se parametri invalidi

### 🎨 Output Colorato
- Cyan: Informazioni generali
- Yellow: Warning e parametri
- Red: Errori
- Green: Successo

---

## 🔄 MODALITÀ OPERATIVE

### DRYRUN Mode
- Simula l'operazione senza eseguirla
- Mostra cosa verrebbe copiato
- Utile per verificare i parametri
- Nessuna modifica al filesystem

### LIVE Mode
- Esegue realmente la copia
- Usa `Copy-Item` con `-Recurse -Force`
- Log dell'operazione completata
- Modifica il filesystem

---

## 📈 MONITORAGGIO

### Visualizza Log Recenti
```powershell
Get-Content "D:\Gene1799\Logs\master_orchestrator.log" -Tail 30
```

### Visualizza Solo Errori
```powershell
Get-Content "D:\Gene1799\Logs\master_orchestrator.log" | Select-String "\[ERROR\]"
```

### Statistiche Log
```powershell
$log = Get-Content "D:\Gene1799\Logs\master_orchestrator.log"
$errors = ($log | Select-String "\[ERROR\]").Count
$success = ($log | Select-String "\[SUCCESS\]").Count
Write-Host "Errors: $errors | Success: $success"
```

---

## ⚠️ TROUBLESHOOTING

### "Script non riconosciuto"
**Problema:** 
```
.\master_repair.ps1: The term '.\master_repair.ps1' is not recognized...
```

**Soluzione:**
```powershell
# 1. Verifica che il file esista
Test-Path .\master_repair.ps1

# 2. Imposta execution policy
Set-ExecutionPolicy Bypass -Scope Process -Force

# 3. Sblocca il file
Unblock-File .\master_repair.ps1

# 4. Riprova
.\master_repair.ps1
```

### "Access Denied"
**Problema:** Permessi insufficienti

**Soluzione:**
```powershell
# Esegui PowerShell come Amministratore
# Tasto destro su PowerShell → "Esegui come amministratore"
```

### Script si blocca
**Problema:** Richiesta di conferma o input

**Soluzione:**
```powershell
# Usa -Force per evitare prompt
$params = @{
    Mode = "LIVE"
    From = "D:\Gene1799\Exp"
    To   = "D:\Gene1799\Modules"
}
& .\hub_explorer.ps1 @params
```

---

## 🎓 BEST PRACTICES

### 1. Backup Prima di Modifiche Importanti
```powershell
# Backup manuale
Copy-Item "D:\Gene1799\Explorer\hub_explorer.ps1" `
          "D:\Gene1799\Explorer\hub_explorer.ps1.manual_backup_$(Get-Date -Format 'yyyyMMdd')"
```

### 2. Test con DRYRUN Prima di LIVE
```powershell
# Sempre testare prima
.\hub_explorer.ps1 -Mode DRYRUN

# Se tutto ok, eseguire live
.\hub_explorer.ps1 -Mode LIVE
```

### 3. Monitoraggio Regolare dei Log
```powershell
# Controlla errori giornalmente
Get-Content "D:\Gene1799\Logs\master_orchestrator.log" | Select-String "\[ERROR\]" -Context 2
```

### 4. Archiviazione Log Periodica
```powershell
# Archivia ogni settimana
.\cleanup_logs.ps1
```

---

## 📞 SUPPORTO

### Log per Debugging
Se riscontri problemi, conserva questi file per il debugging:

1. **Log corrente:** `D:\Gene1799\Logs\master_orchestrator.log`
2. **Log archiviati:** `E:\Gene1799_Data\Logs_Archive\master_orchestrator_*.log`
3. **Backup script:** `D:\Gene1799\Explorer\hub_explorer.ps1.backup_*`

### Informazioni di Sistema
```powershell
# Versione PowerShell
$PSVersionTable

# Paths critici
Get-ChildItem D:\Gene1799 -Recurse -Directory

# Ultimo errore
$Error[0] | Format-List * -Force
```

---

## ✅ CHECKLIST POST-RIPARAZIONE

- [ ] `master_repair.ps1` eseguito con successo
- [ ] Nessun errore di sintassi in hub_explorer.ps1
- [ ] Test DRYRUN completato
- [ ] Test LIVE completato
- [ ] Log pulito (nessun errore Safe-Action)
- [ ] Backup vecchi script presenti
- [ ] Directory critiche create (Exp, Modules, Config, Logs)

---

## 📅 MANUTENZIONE SUGGERITA

| Frequenza | Azione | Script |
|-----------|--------|--------|
| Settimanale | Archivia log | `cleanup_logs.ps1` |
| Mensile | Verifica backup | Controllo manuale `*.backup_*` |
| Prima modifiche | Backup manuale | `Copy-Item` |
| Dopo errori | Diagnostica completa | `diagnose_and_fix.ps1` |

---

## 🎉 CONCLUSIONE

Hai ora a disposizione un toolkit completo per gestire il sistema GENE1799:

- **master_repair.ps1:** Risolve tutto automaticamente
- **hub_explorer.ps1:** Script principale corretto e robusto
- **Sistema di logging:** Pulito e funzionale
- **Backup automatici:** Sicurezza garantita

**Prossimi passi:**
1. Esegui `master_repair.ps1`
2. Verifica che non ci siano errori
3. Usa `hub_explorer.ps1` normalmente
4. Monitora i log regolarmente

---

*Generato il: 03/02/2026*  
*Toolkit Version: 3.0*
