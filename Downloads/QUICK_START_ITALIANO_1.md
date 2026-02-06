# 🚀 GENE1799 - GUIDA RAPIDA START

## ⚡ INSTALLAZIONE IN 3 PASSI

### 1️⃣ ABILITA SCRIPT (Solo la prima volta)
Apri PowerShell come **Amministratore** e esegui:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Digita `S` quando richiesto.

### 2️⃣ VAI NELLA CARTELLA DEI FILE
```powershell
cd C:\Users\TUO_USERNAME\Downloads
```
*(Sostituisci TUO_USERNAME con il tuo nome utente)*

### 3️⃣ ESEGUI SETUP
```powershell
.\gene1799_quick_setup.ps1 -FullSetup -CreateDemoAgents
```

✅ **FATTO!** Il sistema è installato in: `D:\Gene1799\Explorer`

---

## 🎮 COME USARLO

### METODO 1: Interfaccia Grafica (FACILE)
```powershell
cd D:\Gene1799\Explorer
.\gene1799_desktop_monitor_gui.ps1
```

### METODO 2: Comandi Base

**Crea un agente:**
```powershell
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "MioBot" -AgentType "FILE_MANAGER"
```

**Allena l'agente:**
```powershell
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "MioBot" -TrainingCycles 20
```

**Attiva l'agente:**
```powershell
.\gene1799_ai_agent_system.ps1 -Mode DEPLOY -AgentName "MioBot"
```

---

## 🗂️ ORGANIZZA FILE AUTOMATICAMENTE

**Organizza Downloads:**
```powershell
.\gene1799_file_manager.ps1 -Mode ORGANIZE -TargetPath "$env:USERPROFILE\Downloads"
```

**Test senza modificare (consigliato prima):**
```powershell
.\gene1799_file_manager.ps1 -Mode ORGANIZE -TargetPath "$env:USERPROFILE\Downloads" -DryRun
```

**Pulizia automatica:**
```powershell
.\gene1799_file_manager.ps1 -Mode CLEANUP
```

**Tutto insieme:**
```powershell
.\gene1799_file_manager.ps1 -Mode AUTO
```

---

## 🤖 TIPI DI AGENTI

Scegli uno quando crei un agente:

| Tipo | Cosa fa |
|------|---------|
| `SOCIAL_MEDIA` | Gestisce Facebook, Instagram, Twitter, LinkedIn |
| `FILE_MANAGER` | Organizza file automaticamente |
| `DATA_ANALYST` | Analizza dati e crea report |
| `CONTENT_CREATOR` | Crea testi, immagini, video |

---

## 💡 ESEMPIO COMPLETO

```powershell
# Vai nella cartella
cd D:\Gene1799\Explorer

# Crea agente per organizzare file
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "Organizer" -AgentType "FILE_MANAGER"

# Allenalo (30 cicli)
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "Organizer" -TrainingCycles 30

# Attivalo
.\gene1799_ai_agent_system.ps1 -Mode DEPLOY -AgentName "Organizer"

# Test organizzazione Downloads (senza modificare)
.\gene1799_file_manager.ps1 -Mode ORGANIZE -TargetPath "$env:USERPROFILE\Downloads" -DryRun

# Se va bene, organizza per davvero!
.\gene1799_file_manager.ps1 -Mode ORGANIZE -TargetPath "$env:USERPROFILE\Downloads"
```

---

## 📊 COMANDI UTILI

```powershell
# Status di tutti gli agenti
.\gene1799_ai_agent_system.ps1 -Mode STATUS

# Evolvi gli agenti (li fa migliorare!)
.\gene1799_ai_agent_system.ps1 -Mode EVOLVE

# Backup documenti
.\gene1799_file_manager.ps1 -Mode BACKUP -TargetPath "$env:USERPROFILE\Documents"
```

---

## ❓ PROBLEMI COMUNI

**"Script cannot be loaded"**
→ Esegui: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

**"File not found"**
→ Assicurati di essere in: `D:\Gene1799\Explorer`

**Agente non migliora**
→ Più training! Prova: `-TrainingCycles 50`

---

## 🎯 COSA SUCCEDE

1. **Crei** un agente → Ha skills base
2. **Lo alleni** → Impara e migliora
3. **Lo attivi** → Lavora in autonomia
4. **Impara dall'esperienza** → Diventa più bravo
5. **Evolve** → Aumenta livello e autonomia

**Più lavora = Più impara = Più è autonomo!** 🚀

---

## 📖 DOCUMENTAZIONE COMPLETA

Leggi: `INSTALLAZIONE_GUIDA_COMPLETA.md` per:
- Spiegazione dettagliata auto-apprendimento
- Tutti i comandi disponibili
- Best practices
- Troubleshooting avanzato
- Esempi pratici per ogni scenario

---

## ✨ QUICK START TIPS

✅ **Inizia con FILE_MANAGER** - È il più facile da vedere in azione  
✅ **Usa sempre -DryRun** prima per testare  
✅ **Allena minimo 20 cicli** prima di usare l'agente  
✅ **Monitora con la GUI** - È molto più comodo!  
✅ **Fai EVOLVE ogni settimana** - Gli agenti migliorano!  

---

**DIVERTITI! 🎉**

Per domande: gene1799@artcorporation.com
