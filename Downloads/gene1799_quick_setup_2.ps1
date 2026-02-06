#Requires -Version 7.0
<#
.SYNOPSIS
    GENE1799 Quick Setup - Inizializzazione Sistema 1 Minuto
.DESCRIPTION
    Setup rapido completo del sistema Gene1799 AI con tutti gli agenti
.AUTHOR
    Gene1799 Art Corporation
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$FullSetup,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateDemoAgents
)

# ═══════════════════════════════════════════════════════════════════
#  BANNER
# ═══════════════════════════════════════════════════════════════════

Clear-Host

$banner = @"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ██████╗ ███████╗███╗   ██╗███████╗ ██╗███████╗ █████╗  █████╗ ║
║  ██╔════╝ ██╔════╝████╗  ██║██╔════╝███║╚════██║██╔══██╗██╔══██╗║
║  ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ╚██║    ██╔╝╚██████║╚██████║║
║  ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝   ██║   ██╔╝  ╚═══██║ ╚═══██║║
║  ╚██████╔╝███████╗██║ ╚████║███████╗ ██║   ██║    █████║  █████║║
║   ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═╝   ╚═╝   ╚════╝  ╚════╝║
║                                                                  ║
║              AI AUTONOMOUS AGENT SYSTEM - v1.0.0                ║
║              Quick Setup & Initialization Tool                  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
"@

Write-Host $banner -ForegroundColor Cyan

Write-Host "`n🚀 BENVENUTO NEL SETUP GENE1799 AI SYSTEM`n" -ForegroundColor Yellow
Write-Host "Questo script configurerà:" -ForegroundColor White
Write-Host "  ✓ Struttura directory completa" -ForegroundColor Green
Write-Host "  ✓ Sistema di integrazione AI core" -ForegroundColor Green
Write-Host "  ✓ Knowledge base e apprendimento" -ForegroundColor Green
Write-Host "  ✓ Agenti AI specializzati (opzionale)" -ForegroundColor Green
Write-Host "  ✓ Monitor GUI desktop" -ForegroundColor Green
Write-Host ""

# ═══════════════════════════════════════════════════════════════════
#  STEP 1: VERIFICA REQUISITI
# ═══════════════════════════════════════════════════════════════════

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 1: Verifica Requisiti" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

Write-Host "`n⚙️ Controllo PowerShell versione..." -ForegroundColor Cyan
$psVersion = $PSVersionTable.PSVersion
Write-Host "   PowerShell $($psVersion.Major).$($psVersion.Minor) " -ForegroundColor Green -NoNewline
Write-Host "✓" -ForegroundColor Green

Write-Host "⚙️ Controllo execution policy..." -ForegroundColor Cyan
$policy = Get-ExecutionPolicy
Write-Host "   Policy corrente: $policy " -ForegroundColor Yellow -NoNewline

if ($policy -eq 'Restricted') {
    Write-Host "⚠" -ForegroundColor Yellow
    Write-Host "`n   ⚠️ WARNING: Execution policy è Restricted" -ForegroundColor Yellow
    Write-Host "   Per eseguire gli script, esegui come amministratore:" -ForegroundColor Gray
    Write-Host "   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "Vuoi continuare comunque? (s/n)"
    if ($continue -ne 's') {
        Write-Host "`n❌ Setup annullato" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "✓" -ForegroundColor Green
}

Write-Host "⚙️ Controllo spazio disco..." -ForegroundColor Cyan
$drive = Get-PSDrive D -ErrorAction SilentlyContinue
if ($drive) {
    $freeSpaceGB = $drive.Free / 1GB
    Write-Host "   Drive D: - $($freeSpaceGB.ToString('F2')) GB liberi " -ForegroundColor Green -NoNewline
    Write-Host "✓" -ForegroundColor Green
}
else {
    Write-Host "   ⚠️ Drive D: non trovato, verrà usato il drive corrente" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# ═══════════════════════════════════════════════════════════════════
#  STEP 2: CREAZIONE STRUTTURA
# ═══════════════════════════════════════════════════════════════════

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 2: Creazione Struttura Directory" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$basePath = "D:\Gene1799\Explorer"

$directories = @(
    $basePath,
    "$basePath\Agents\SOCIAL_MEDIA",
    "$basePath\Agents\FILE_MANAGER",
    "$basePath\Agents\DATA_ANALYST",
    "$basePath\Agents\CONTENT_CREATOR",
    "$basePath\Data\FileRules",
    "$basePath\Data\FilePatterns",
    "$basePath\Logs",
    "$basePath\Knowledge\Experiences",
    "$basePath\Knowledge\Patterns",
    "$basePath\Knowledge\ErrorCorrections",
    "$basePath\Models",
    "$basePath\Backup",
    "$basePath\Config"
)

Write-Host ""
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "  📁 Creata: " -ForegroundColor Gray -NoNewline
        Write-Host "$dir" -ForegroundColor White
    }
    else {
        Write-Host "  ✓ Esiste: " -ForegroundColor Green -NoNewline
        Write-Host "$dir" -ForegroundColor Gray
    }
}

Start-Sleep -Seconds 1

# ═══════════════════════════════════════════════════════════════════
#  STEP 3: COPIA SCRIPT
# ═══════════════════════════════════════════════════════════════════

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 3: Installazione Script Sistema" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

Write-Host ""
Write-Host "📋 Verifica script nella directory corrente..." -ForegroundColor Cyan

$scripts = @(
    "gene1799_ai_integration_core.ps1",
    "gene1799_ai_agent_system.ps1",
    "gene1799_file_manager.ps1",
    "gene1799_desktop_monitor_gui.ps1"
)

$scriptsFound = 0
foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "  ✓ Trovato: $script" -ForegroundColor Green
        
        # Copia nello stesso directory
        $destPath = Join-Path $basePath $script
        Copy-Item -Path $script -Destination $destPath -Force
        Write-Host "    → Copiato in: $destPath" -ForegroundColor Gray
        $scriptsFound++
    }
    else {
        Write-Host "  ⚠ Non trovato: $script" -ForegroundColor Yellow
    }
}

if ($scriptsFound -eq 0) {
    Write-Host "`n⚠️ Nessuno script trovato nella directory corrente!" -ForegroundColor Yellow
    Write-Host "Gli script dovrebbero essere scaricati e posizionati nella stessa cartella." -ForegroundColor Gray
}

Start-Sleep -Seconds 1

# ═══════════════════════════════════════════════════════════════════
#  STEP 4: INIZIALIZZAZIONE CORE
# ═══════════════════════════════════════════════════════════════════

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 4: Inizializzazione AI Core" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

Write-Host ""
Write-Host "🧠 Inizializzazione Knowledge Base..." -ForegroundColor Cyan

$coreScript = Join-Path $basePath "gene1799_ai_integration_core.ps1"
if (Test-Path $coreScript) {
    & $coreScript -Mode INIT
    Write-Host "`n✅ Core inizializzato con successo!" -ForegroundColor Green
}
else {
    Write-Host "⚠️ Script core non trovato, inizializzazione manuale richiesta" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# ═══════════════════════════════════════════════════════════════════
#  STEP 5: CREAZIONE AGENTI DEMO (OPZIONALE)
# ═══════════════════════════════════════════════════════════════════

if ($CreateDemoAgents -or $FullSetup) {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "STEP 5: Creazione Agenti Demo" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    Write-Host ""
    Write-Host "🤖 Creazione agenti di esempio..." -ForegroundColor Cyan
    
    $agentScript = Join-Path $basePath "gene1799_ai_agent_system.ps1"
    
    if (Test-Path $agentScript) {
        $demoAgents = @(
            @{Name="SocialBot"; Type="SOCIAL_MEDIA"},
            @{Name="FileOrganizer"; Type="FILE_MANAGER"},
            @{Name="DataAnalyst"; Type="DATA_ANALYST"},
            @{Name="ContentCreator"; Type="CONTENT_CREATOR"}
        )
        
        foreach ($agent in $demoAgents) {
            Write-Host "`n  📝 Creazione: $($agent.Name) [$($agent.Type)]..." -ForegroundColor Yellow
            
            Start-Process powershell -ArgumentList `
                "-NoExit", "-Command", `
                "& '$agentScript' -Mode CREATE -AgentName '$($agent.Name)' -AgentType $($agent.Type); Read-Host 'Premi Enter per chiudere'" `
                -Wait
            
            Write-Host "  ✅ $($agent.Name) creato!" -ForegroundColor Green
            Start-Sleep -Seconds 1
        }
        
        Write-Host "`n✅ Tutti gli agenti demo sono stati creati!" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Script agenti non trovato" -ForegroundColor Yellow
    }
}

# ═══════════════════════════════════════════════════════════════════
#  STEP 6: CREAZIONE SHORTCUTS
# ═══════════════════════════════════════════════════════════════════

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 6: Creazione Collegamenti" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

Write-Host ""
Write-Host "🔗 Creazione script di lancio rapido..." -ForegroundColor Cyan

# Launcher per GUI
$guiLauncher = @"
@echo off
title GENE1799 Control Center
cd /d "$basePath"
powershell.exe -ExecutionPolicy Bypass -File "gene1799_desktop_monitor_gui.ps1"
"@

$guiLauncherPath = Join-Path $basePath "Launch_ControlCenter.bat"
$guiLauncher | Set-Content -Path $guiLauncherPath -Encoding ASCII
Write-Host "  ✓ Creato: Launch_ControlCenter.bat" -ForegroundColor Green

# Launcher per File Manager
$fileLauncher = @"
@echo off
title GENE1799 File Manager
cd /d "$basePath"
powershell.exe -ExecutionPolicy Bypass -File "gene1799_file_manager.ps1" -Mode AUTO
pause
"@

$fileLauncherPath = Join-Path $basePath "Launch_FileManager.bat"
$fileLauncher | Set-Content -Path $fileLauncherPath -Encoding ASCII
Write-Host "  ✓ Creato: Launch_FileManager.bat" -ForegroundColor Green

# Quick Commands Script
$quickCommands = @"
# GENE1799 Quick Commands
# Copia e incolla questi comandi nel tuo terminale

# Cambia nella directory Gene1799
cd D:\Gene1799\Explorer

# Avvia GUI Control Center
.\gene1799_desktop_monitor_gui.ps1

# Crea nuovo agente
.\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "MioAgente" -AgentType "FILE_MANAGER"

# Allena un agente
.\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "MioAgente" -TrainingCycles 20

# Deploy agente
.\gene1799_ai_agent_system.ps1 -Mode DEPLOY -AgentName "MioAgente"

# Status sistema
.\gene1799_ai_agent_system.ps1 -Mode STATUS

# Organizza file automaticamente
.\gene1799_file_manager.ps1 -Mode ORGANIZE -TargetPath "$env:USERPROFILE\Downloads"

# Pulizia automatica
.\gene1799_file_manager.ps1 -Mode CLEANUP -TargetPath "$env:USERPROFILE\Downloads"

# Backup
.\gene1799_file_manager.ps1 -Mode BACKUP -TargetPath "$env:USERPROFILE\Documents"

# Evoluzione agenti
.\gene1799_ai_agent_system.ps1 -Mode EVOLVE
"@

$quickCommandsPath = Join-Path $basePath "QuickCommands.txt"
$quickCommands | Set-Content -Path $quickCommandsPath -Encoding UTF8
Write-Host "  ✓ Creato: QuickCommands.txt" -ForegroundColor Green

Start-Sleep -Seconds 1

# ═══════════════════════════════════════════════════════════════════
#  STEP 7: README & DOCUMENTAZIONE
# ═══════════════════════════════════════════════════════════════════

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 7: Generazione Documentazione" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$readme = @"
╔══════════════════════════════════════════════════════════════════╗
║                    GENE1799 AI SYSTEM v1.0.0                    ║
║              Sistema Agenti AI Autonomi e Auto-Apprendenti       ║
╚══════════════════════════════════════════════════════════════════╝

📖 INTRODUZIONE
===============
Gene1799 è un sistema completo di agenti AI autonomi che:
- Si auto-istruiscono attraverso l'esperienza
- Imparano dai successi e dagli errori
- Crescono in autonomia e capacità
- Gestiscono profili social, file, analisi dati e contenuti

🚀 AVVIO RAPIDO
===============

1. AVVIA IL CONTROL CENTER
   Doppio click su: Launch_ControlCenter.bat
   Oppure: .\gene1799_desktop_monitor_gui.ps1

2. CREA IL TUO PRIMO AGENTE
   .\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName "Bot1" -AgentType "FILE_MANAGER"

3. ALLENA L'AGENTE
   .\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName "Bot1" -TrainingCycles 20

4. DEPLOY IN PRODUZIONE
   .\gene1799_ai_agent_system.ps1 -Mode DEPLOY -AgentName "Bot1"

🤖 TIPI DI AGENTI
=================

SOCIAL_MEDIA
- Gestisce profili Facebook, Instagram, Twitter, LinkedIn
- Crea e schedula contenuti
- Analizza engagement e crescita audience
- Risponde a commenti automaticamente
- Ottimizza hashtag e posting times

FILE_MANAGER
- Organizza file automaticamente per categoria
- Rileva e rimuove duplicati
- Backup intelligenti
- Pulizia automatica file temporanei
- Tag e classificazione smart

DATA_ANALYST
- Raccoglie e analizza dati
- Genera report automatici
- Identifica pattern e trend
- Analisi predittive
- Visualizzazioni e grafici

CONTENT_CREATOR
- Genera contenuti testuali
- Crea grafiche e immagini
- Editing video
- Ottimizzazione SEO
- Contenuti multilingua

🧠 AUTO-APPRENDIMENTO
=====================

Gli agenti imparano in 3 modi:

1. ESPERIENZA DIRETTA
   Ogni azione eseguita viene registrata con:
   - Contesto
   - Risultato (successo/fallimento)
   - Metriche di performance
   
2. RICONOSCIMENTO PATTERN
   Dopo 10+ esperienze simili, il sistema:
   - Identifica pattern di successo
   - Crea best practices automatiche
   - Applica le strategie vincenti

3. AUTO-CORREZIONE
   Quando si verifica un errore:
   - Analizza il problema
   - Cerca soluzioni simili nella KB
   - Adatta il comportamento
   - Previene errori futuri

📊 MONITORING & CONTROLLO
==========================

CONTROL CENTER GUI
- Dashboard in tempo reale
- Status di tutti gli agenti
- Performance metrics
- Knowledge base stats
- Controllo operazioni

COMANDI PRINCIPALI
- STATUS: Visualizza stato sistema
- TRAIN: Allena un agente
- DEPLOY: Attiva un agente
- EVOLVE: Evolvi tutti gli agenti
- ORGANIZE: Organizza file
- CLEANUP: Pulizia sistema

🎯 AUTONOMIA AGENTI
===================

Livelli di Autonomia:
- 0.0-0.3: Richiede approvazione per ogni azione
- 0.3-0.6: Autonomia parziale, chiede conferma azioni critiche
- 0.6-0.8: Alta autonomia, lavora in modo indipendente
- 0.8-1.0: Autonomia completa, self-managing

L'autonomia cresce con:
- Performance consistente (>80%)
- Numero di azioni completate
- Varietà di situazioni gestite
- Capacità di auto-correzione

📁 STRUTTURA DIRECTORY
======================

D:\Gene1799\Explorer\
├── Agents/           # Agenti AI e loro configurazioni
│   ├── SOCIAL_MEDIA/
│   ├── FILE_MANAGER/
│   ├── DATA_ANALYST/
│   └── CONTENT_CREATOR/
├── Knowledge/        # Knowledge Base condivisa
│   ├── Experiences/
│   ├── Patterns/
│   └── ErrorCorrections/
├── Data/            # Dati e patterns file
├── Logs/            # Log sistema
├── Models/          # Modelli ML (future)
├── Backup/          # Backup automatici
└── Config/          # Configurazioni sistema

🔧 TROUBLESHOOTING
==================

Problema: Script non si avvia
Soluzione: Controlla execution policy
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

Problema: Agente non impara
Soluzione: Esegui più cicli di training
  -TrainingCycles 50 (invece di 10)

Problema: Performance bassa
Soluzione: Evolvi gli agenti
  .\gene1799_ai_agent_system.ps1 -Mode EVOLVE

Problema: Knowledge base corrotta
Soluzione: Elimina e reinizializza
  Remove-Item D:\Gene1799\Explorer\Knowledge\* -Recurse
  .\gene1799_ai_integration_core.ps1 -Mode INIT

📞 SUPPORTO
===========

Per domande, bug report o suggerimenti:
- Email: gene1799@artcorporation.com
- GitHub: github.com/gene1799/ai-system
- Discord: discord.gg/gene1799

🎉 BUON LAVORO CON GENE1799!
============================

Ricorda: più gli agenti lavorano, più imparano e diventano capaci!

"@

$readmePath = Join-Path $basePath "README.txt"
$readme | Set-Content -Path $readmePath -Encoding UTF8
Write-Host "  ✓ Creato: README.txt" -ForegroundColor Green

Start-Sleep -Seconds 1

# ═══════════════════════════════════════════════════════════════════
#  COMPLETAMENTO
# ═══════════════════════════════════════════════════════════════════

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "SETUP COMPLETATO CON SUCCESSO!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                 🎉 GENE1799 È PRONTO! 🎉                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host ""
Write-Host "📁 Directory principale:" -ForegroundColor Yellow
Write-Host "   $basePath" -ForegroundColor White

Write-Host ""
Write-Host "🚀 PROSSIMI PASSI:" -ForegroundColor Magenta
Write-Host ""
Write-Host "1️⃣  AVVIA IL CONTROL CENTER" -ForegroundColor Cyan
Write-Host "   cd $basePath" -ForegroundColor Gray
Write-Host "   .\Launch_ControlCenter.bat" -ForegroundColor White
Write-Host ""

Write-Host "2️⃣  CREA IL TUO PRIMO AGENTE" -ForegroundColor Cyan
Write-Host "   .\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName ""Bot1"" -AgentType ""FILE_MANAGER""" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣  ALLENA L'AGENTE" -ForegroundColor Cyan
Write-Host "   .\gene1799_ai_agent_system.ps1 -Mode TRAIN -AgentName ""Bot1"" -TrainingCycles 20" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣  ATTIVA L'AGENTE" -ForegroundColor Cyan
Write-Host "   .\gene1799_ai_agent_system.ps1 -Mode DEPLOY -AgentName ""Bot1""" -ForegroundColor White
Write-Host ""

Write-Host "📚 DOCUMENTAZIONE:" -ForegroundColor Magenta
Write-Host "   Leggi: $basePath\README.txt" -ForegroundColor White
Write-Host "   Comandi rapidi: $basePath\QuickCommands.txt" -ForegroundColor White
Write-Host ""

Write-Host "💡 SUGGERIMENTO:" -ForegroundColor Yellow
Write-Host "   Usa la GUI per gestire tutto comodamente!" -ForegroundColor Gray
Write-Host ""

# Opzione di lanciare la GUI immediatamente
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
$launch = Read-Host "`nVuoi avviare il Control Center ora? (s/n)"

if ($launch -eq 's' -or $launch -eq 'S') {
    Write-Host "`n🚀 Avvio Control Center..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    
    $guiScript = Join-Path $basePath "gene1799_desktop_monitor_gui.ps1"
    if (Test-Path $guiScript) {
        & $guiScript
    }
}
else {
    Write-Host "`n👋 A presto! Esegui Launch_ControlCenter.bat quando sei pronto." -ForegroundColor Cyan
}

Write-Host "`n✨ Buon lavoro con Gene1799 AI System! ✨`n" -ForegroundColor Green
