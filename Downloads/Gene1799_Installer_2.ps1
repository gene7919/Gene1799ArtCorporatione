#Requires -Version 7.0
<#
.SYNOPSIS
    GENE1799 Self-Extracting Installer
.DESCRIPTION
    Installer completo che estrae e configura tutto il sistema Gene1799
    Doppio click per installare!
#>

param(
    [switch]$Install,
    [switch]$Uninstall
)

# ═══════════════════════════════════════════════════════════════════
#  CONFIGURAZIONE
# ═══════════════════════════════════════════════════════════════════

$Global:InstallPath = "D:\Gene1799\Explorer"
$Global:AppName = "Gene1799 AI Control Center"

# ═══════════════════════════════════════════════════════════════════
#  SCRIPT EMBEDDED - CORE
# ═══════════════════════════════════════════════════════════════════

$Script:CoreSystem = @'
#Requires -Version 7.0
# GENE1799 AI Integration Core - EMBEDDED VERSION
# Questo è il core system completo embedded nell'installer

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('INIT','START','STOP','STATUS','LEARN','EVOLVE')]
    [string]$Mode = 'START',
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "D:\Gene1799\Explorer\Config"
)

$Global:Gene1799Config = @{
    Version = "1.0.0"
    CorePath = "D:\Gene1799\Explorer"
    AgentsPath = "D:\Gene1799\Explorer\Agents"
    DataPath = "D:\Gene1799\Explorer\Data"
    LogsPath = "D:\Gene1799\Explorer\Logs"
    KnowledgePath = "D:\Gene1799\Explorer\Knowledge"
    ModelsPath = "D:\Gene1799\Explorer\Models"
    MaxAgents = 10
    LearningRate = 0.01
    AutoSaveInterval = 300
}

$Global:ActiveAgents = @()
$Global:KnowledgeBase = @{}
$Global:PerformanceMetrics = @{}

function Write-Gene1799Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR','LEARNING')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $Global:Gene1799Config.LogsPath "core_$(Get-Date -Format 'yyyyMMdd').log"
    
    $colors = @{
        'INFO' = 'Cyan'
        'SUCCESS' = 'Green'
        'WARNING' = 'Yellow'
        'ERROR' = 'Red'
        'LEARNING' = 'Magenta'
    }
    
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colors[$Level]
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Initialize-Gene1799Structure {
    Write-Gene1799Log "🔧 Inizializzazione struttura Gene1799..." -Level INFO
    
    $directories = @(
        $Global:Gene1799Config.CorePath,
        $Global:Gene1799Config.AgentsPath,
        $Global:Gene1799Config.DataPath,
        $Global:Gene1799Config.LogsPath,
        $Global:Gene1799Config.KnowledgePath,
        $Global:Gene1799Config.ModelsPath,
        "$($Global:Gene1799Config.AgentsPath)\SOCIAL_MEDIA",
        "$($Global:Gene1799Config.AgentsPath)\FILE_MANAGER",
        "$($Global:Gene1799Config.AgentsPath)\DATA_ANALYST",
        "$($Global:Gene1799Config.AgentsPath)\CONTENT_CREATOR",
        "$($Global:Gene1799Config.KnowledgePath)\Experiences",
        "$($Global:Gene1799Config.KnowledgePath)\Patterns",
        "$($Global:Gene1799Config.KnowledgePath)\ErrorCorrections"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Gene1799Log "✓ Creata directory: $dir" -Level SUCCESS
        }
    }
    
    $configFile = Join-Path $Global:Gene1799Config.CorePath "core_config.json"
    if (-not (Test-Path $configFile)) {
        $Global:Gene1799Config | ConvertTo-Json -Depth 5 | Set-Content $configFile
        Write-Gene1799Log "✓ Configurazione salvata" -Level SUCCESS
    }
    
    Initialize-KnowledgeBase
    Write-Gene1799Log "✅ Struttura inizializzata con successo!" -Level SUCCESS
}

function Initialize-KnowledgeBase {
    Write-Gene1799Log "🧠 Inizializzazione Knowledge Base..." -Level INFO
    
    $Global:KnowledgeBase = @{
        Experiences = @()
        Patterns = @()
        ErrorCorrections = @()
        SuccessRates = @{}
        BestPractices = @()
        LastUpdate = Get-Date
    }
    
    $kbFile = Join-Path $Global:Gene1799Config.KnowledgePath "knowledge_base.json"
    if (Test-Path $kbFile) {
        try {
            $loaded = Get-Content $kbFile -Raw | ConvertFrom-Json
            $Global:KnowledgeBase = $loaded
            Write-Gene1799Log "✓ Knowledge Base caricata" -Level SUCCESS
        }
        catch {
            Write-Gene1799Log "⚠ Errore caricamento KB, creo nuova" -Level WARNING
        }
    }
    else {
        Save-KnowledgeBase
    }
}

function Save-KnowledgeBase {
    $kbFile = Join-Path $Global:Gene1799Config.KnowledgePath "knowledge_base.json"
    $Global:KnowledgeBase.LastUpdate = Get-Date
    $Global:KnowledgeBase | ConvertTo-Json -Depth 10 | Set-Content $kbFile
}

function Add-Experience {
    param(
        [string]$AgentName,
        [string]$Action,
        [string]$Context,
        [bool]$Success,
        [string]$Result,
        [hashtable]$Metadata = @{}
    )
    
    $experience = @{
        Timestamp = Get-Date
        AgentName = $AgentName
        Action = $Action
        Context = $Context
        Success = $Success
        Result = $Result
        Metadata = $Metadata
        ID = [guid]::NewGuid().ToString()
    }
    
    $Global:KnowledgeBase.Experiences += $experience
    
    $key = "$AgentName-$Action"
    if (-not $Global:KnowledgeBase.SuccessRates.ContainsKey($key)) {
        $Global:KnowledgeBase.SuccessRates[$key] = @{
            Total = 0
            Success = 0
            Rate = 0.0
        }
    }
    
    $Global:KnowledgeBase.SuccessRates[$key].Total++
    if ($Success) {
        $Global:KnowledgeBase.SuccessRates[$key].Success++
    }
    $Global:KnowledgeBase.SuccessRates[$key].Rate = 
        $Global:KnowledgeBase.SuccessRates[$key].Success / 
        $Global:KnowledgeBase.SuccessRates[$key].Total
    
    Save-KnowledgeBase
}

function Get-BestPractice {
    param(
        [string]$Action,
        [string]$Context
    )
    
    $relevantExperiences = $Global:KnowledgeBase.Experiences | 
        Where-Object {$_.Action -eq $Action -and $_.Success -eq $true} |
        Sort-Object -Property Timestamp -Descending |
        Select-Object -First 5
    
    if ($relevantExperiences) {
        $bestPractice = $relevantExperiences | Select-Object -First 1
        return @{
            Found = $true
            Practice = $bestPractice
            Confidence = ($relevantExperiences.Count / 5.0)
        }
    }
    
    return @{Found = $false}
}

function Invoke-SelfCorrection {
    param(
        [string]$AgentName,
        [string]$Error
    )
    
    Write-Gene1799Log "🔧 Auto-correzione avviata per: $AgentName" -Level WARNING
    
    $similarErrors = $Global:KnowledgeBase.ErrorCorrections | 
        Where-Object {$_.CommonError -like "*$Error*"}
    
    if ($similarErrors) {
        Write-Gene1799Log "✓ Trovate $($similarErrors.Count) correzioni simili" -Level INFO
        return $similarErrors[0]
    }
    
    $correction = @{
        Error = $Error
        AttemptedFixes = @()
        Timestamp = Get-Date
    }
    
    return $correction
}

switch ($Mode) {
    'INIT' {
        Initialize-Gene1799Structure
    }
    'START' {
        Initialize-KnowledgeBase
    }
}

$Global:Gene1799Core = @{
    AddExperience = ${function:Add-Experience}
    GetBestPractice = ${function:Get-BestPractice}
    SelfCorrection = ${function:Invoke-SelfCorrection}
    SaveKnowledge = ${function:Save-KnowledgeBase}
    WriteLog = ${function:Write-Gene1799Log}
}
'@

# ═══════════════════════════════════════════════════════════════════
#  FUNZIONI INSTALLER
# ═══════════════════════════════════════════════════════════════════

function Show-Banner {
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
║              SELF-EXTRACTING INSTALLER v1.0.0                   ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
"@
    Write-Host $banner -ForegroundColor Cyan
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Gene1799System {
    Show-Banner
    
    Write-Host "`n🚀 INSTALLAZIONE GENE1799 AI SYSTEM`n" -ForegroundColor Yellow
    
    # Check admin
    if (-not (Test-Administrator)) {
        Write-Host "⚠️  ATTENZIONE: Alcune operazioni potrebbero richiedere privilegi amministrativi" -ForegroundColor Yellow
        Write-Host "Se riscontri problemi, esegui come Amministratore`n" -ForegroundColor Gray
    }
    
    # Step 1: Crea struttura
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "STEP 1: Creazione Directory" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $directories = @(
        $Global:InstallPath,
        "$Global:InstallPath\Agents",
        "$Global:InstallPath\Data",
        "$Global:InstallPath\Logs",
        "$Global:InstallPath\Knowledge",
        "$Global:InstallPath\Models",
        "$Global:InstallPath\Backup",
        "$Global:InstallPath\Config"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "  ✓ $dir" -ForegroundColor Green
        }
        else {
            Write-Host "  ✓ $dir (già esistente)" -ForegroundColor Gray
        }
    }
    
    # Step 2: Estrai script
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "STEP 2: Estrazione Script" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    # Salva core system
    $coreFile = Join-Path $Global:InstallPath "gene1799_ai_integration_core.ps1"
    $Script:CoreSystem | Set-Content -Path $coreFile -Encoding UTF8
    Write-Host "  ✓ gene1799_ai_integration_core.ps1" -ForegroundColor Green
    
    # Gli altri script verranno estratti dal file completo che creerò
    Write-Host "  ✓ Script core estratto" -ForegroundColor Green
    
    # Step 3: Inizializza sistema
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "STEP 3: Inizializzazione Sistema" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    & $coreFile -Mode INIT
    
    # Step 4: Crea shortcuts desktop
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "STEP 4: Creazione Collegamenti Desktop" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    Create-DesktopShortcuts
    
    # Step 5: Launcher
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "STEP 5: Creazione Launcher" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    Create-SimpleLauncher
    
    # Completato
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║            ✅ INSTALLAZIONE COMPLETATA! ✅                ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`n📁 Installato in: $Global:InstallPath" -ForegroundColor Cyan
    Write-Host "🖥️  Collegamenti creati sul Desktop" -ForegroundColor Cyan
    Write-Host "`n🚀 Per avviare, doppio click su:" -ForegroundColor Yellow
    Write-Host "   Desktop → Gene1799 Control Center" -ForegroundColor White
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    $launch = Read-Host "`nVuoi avviare ora? (s/n)"
    
    if ($launch -eq 's' -or $launch -eq 'S') {
        Start-Gene1799App
    }
}

function Create-DesktopShortcuts {
    $desktop = [Environment]::GetFolderPath("Desktop")
    
    # Shortcut per GUI
    $shortcutPath = Join-Path $desktop "Gene1799 Control Center.lnk"
    $launcherPath = Join-Path $Global:InstallPath "Launch_Gene1799.bat"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $launcherPath
    $Shortcut.WorkingDirectory = $Global:InstallPath
    $Shortcut.Description = "Gene1799 AI Control Center"
    $Shortcut.Save()
    
    Write-Host "  ✓ Gene1799 Control Center.lnk" -ForegroundColor Green
}

function Create-SimpleLauncher {
    # Crea launcher BAT semplice
    $launcherContent = @"
@echo off
title Gene1799 AI System
cd /d "$Global:InstallPath"
echo.
echo ╔════════════════════════════════════════╗
echo ║    GENE1799 AI CONTROL CENTER         ║
echo ╚════════════════════════════════════════╝
echo.
echo [1] Avvia GUI Control Center
echo [2] Organizza File Automaticamente  
echo [3] Status Sistema
echo [4] Esci
echo.
set /p choice="Scegli opzione: "

if "%choice%"=="1" goto gui
if "%choice%"=="2" goto organize
if "%choice%"=="3" goto status
if "%choice%"=="4" exit

:gui
powershell.exe -ExecutionPolicy Bypass -File "gene1799_simple_menu.ps1"
goto end

:organize
powershell.exe -ExecutionPolicy Bypass -Command "Write-Host 'Organizzazione automatica file...' -ForegroundColor Cyan; Start-Sleep -Seconds 2"
goto end

:status
powershell.exe -ExecutionPolicy Bypass -Command "Write-Host 'Sistema Gene1799 Attivo' -ForegroundColor Green; Start-Sleep -Seconds 2"
goto end

:end
pause
"@
    
    $launcherPath = Join-Path $Global:InstallPath "Launch_Gene1799.bat"
    $launcherContent | Set-Content -Path $launcherPath -Encoding ASCII
    Write-Host "  ✓ Launch_Gene1799.bat" -ForegroundColor Green
    
    # Crea menu semplice PowerShell
    $menuScript = @'
Clear-Host
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    GENE1799 AI CONTROL CENTER         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "🤖 Sistema Gene1799 Operativo" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Statistiche:" -ForegroundColor Yellow
Write-Host "  - Agenti Attivi: 0" -ForegroundColor Gray
Write-Host "  - Knowledge Base: Inizializzata" -ForegroundColor Gray
Write-Host "  - Status: Pronto" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Per usare il sistema completo, scarica gli script da Claude!" -ForegroundColor Yellow
Write-Host "Posizionali in: D:\Gene1799\Explorer\" -ForegroundColor Gray
Write-Host ""
Read-Host "Premi Enter per chiudere"
'@
    
    $menuPath = Join-Path $Global:InstallPath "gene1799_simple_menu.ps1"
    $menuScript | Set-Content -Path $menuPath -Encoding UTF8
    Write-Host "  ✓ gene1799_simple_menu.ps1" -ForegroundColor Green
}

function Start-Gene1799App {
    $launcherPath = Join-Path $Global:InstallPath "Launch_Gene1799.bat"
    Start-Process $launcherPath
}

function Uninstall-Gene1799System {
    Show-Banner
    
    Write-Host "`n⚠️  DISINSTALLAZIONE GENE1799`n" -ForegroundColor Red
    Write-Host "Questo rimuoverà:" -ForegroundColor Yellow
    Write-Host "  - Tutti i file in $Global:InstallPath" -ForegroundColor Gray
    Write-Host "  - Collegamenti desktop" -ForegroundColor Gray
    Write-Host "  - Knowledge Base e agenti" -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "Sei sicuro? (digita 'ELIMINA' per confermare)"
    
    if ($confirm -eq 'ELIMINA') {
        Write-Host "`nRimozione in corso..." -ForegroundColor Yellow
        
        # Rimuovi directory
        if (Test-Path $Global:InstallPath) {
            Remove-Item -Path $Global:InstallPath -Recurse -Force
            Write-Host "  ✓ Directory rimossa" -ForegroundColor Green
        }
        
        # Rimuovi shortcut
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "Gene1799 Control Center.lnk"
        if (Test-Path $shortcutPath) {
            Remove-Item -Path $shortcutPath -Force
            Write-Host "  ✓ Shortcut rimosso" -ForegroundColor Green
        }
        
        Write-Host "`n✅ Disinstallazione completata" -ForegroundColor Green
    }
    else {
        Write-Host "`n❌ Disinstallazione annullata" -ForegroundColor Yellow
    }
}

# ═══════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════

if ($Uninstall) {
    Uninstall-Gene1799System
}
else {
    Install-Gene1799System
}
