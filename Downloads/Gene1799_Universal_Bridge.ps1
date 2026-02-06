#Requires -Version 7.0
<#
.SYNOPSIS
    GENE1799 Universal Bridge - Ponte Universale Dati
.DESCRIPTION
    Collega e integra TUTTI i dati esistenti su D:\ e E:\
    Crea ponti di lavoro tra tutti i sistemi Gene1799
.AUTHOR
    Gene1799 Art Corporation
#>

param(
    [switch]$ScanAll,
    [switch]$CreateBridges,
    [switch]$ShowDashboard
)

# ═══════════════════════════════════════════════════════════════════
#  CONFIGURAZIONE PONTI
# ═══════════════════════════════════════════════════════════════════

$Global:BridgeConfig = @{
    MainHub = "D:\Gene1799\Explorer"
    
    # Tutti i percorsi Gene1799 esistenti rilevati
    ExistingPaths = @(
        "D:\Gene1799",
        "D:\Gene1799\Gene1799",
        "D:\Gene1799-backup",
        "D:\Gene1799Hub",
        "E:\"  # Se esiste
    )
    
    # Tipi di dati da collegare
    DataTypes = @{
        Scripts = @("*.ps1")
        Agents = @("Agent*.ps1", "*Orchestrator*")
        Social = @("*Social*", "*Instagram*", "*TikTok*", "*YouTube*", "*X.ps1")
        Tools = @("*Tool*", "*Organizer*", "*Healing*")
        Config = @("*.json", "*.xml", "*.config")
        Logs = @("*.log")
    }
    
    BridgePath = "D:\Gene1799\Explorer\Bridges"
    DataMapPath = "D:\Gene1799\Explorer\DataMap.json"
}

# ═══════════════════════════════════════════════════════════════════
#  SCANSIONE UNIVERSALE
# ═══════════════════════════════════════════════════════════════════

function Scan-AllGene1799Data {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        SCANSIONE UNIVERSALE DATI GENE1799                 ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $discoveredData = @{
        Scripts = @()
        Agents = @()
        Social = @()
        Tools = @()
        Configs = @()
        TotalFiles = 0
        ScanDate = Get-Date
    }
    
    Write-Host "🔍 Scansione drives: D:\ e E:\..." -ForegroundColor Yellow
    Write-Host ""
    
    # Scansione D:\
    if (Test-Path "D:\") {
        Write-Host "📀 Drive D:\" -ForegroundColor Cyan
        $dFiles = Get-ChildItem -Path "D:\" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
        
        foreach ($file in $dFiles) {
            $relativePath = $file.FullName
            
            # Categorizza
            if ($file.Name -like "*Agent*" -or $file.Name -like "*Orchestrator*") {
                $discoveredData.Agents += @{
                    Name = $file.Name
                    Path = $relativePath
                    Size = $file.Length
                    Modified = $file.LastWriteTime
                }
            }
            elseif ($file.Name -like "*Social*" -or $file.Name -like "*Instagram*" -or 
                    $file.Name -like "*TikTok*" -or $file.Name -like "*YouTube*") {
                $discoveredData.Social += @{
                    Name = $file.Name
                    Path = $relativePath
                    Size = $file.Length
                }
            }
            elseif ($file.Name -like "*Tool*" -or $file.Name -like "*Organizer*") {
                $discoveredData.Tools += @{
                    Name = $file.Name
                    Path = $relativePath
                    Size = $file.Length
                }
            }
            else {
                $discoveredData.Scripts += @{
                    Name = $file.Name
                    Path = $relativePath
                    Size = $file.Length
                }
            }
            
            $discoveredData.TotalFiles++
        }
        
        Write-Host "  ✓ Trovati $($dFiles.Count) file .ps1" -ForegroundColor Green
    }
    
    # Scansione E:\ se esiste
    if (Test-Path "E:\") {
        Write-Host "📀 Drive E:\" -ForegroundColor Cyan
        $eFiles = Get-ChildItem -Path "E:\" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
        
        foreach ($file in $eFiles) {
            $discoveredData.Scripts += @{
                Name = $file.Name
                Path = $file.FullName
                Size = $file.Length
                Drive = "E"
            }
            $discoveredData.TotalFiles++
        }
        
        Write-Host "  ✓ Trovati $($eFiles.Count) file .ps1" -ForegroundColor Green
    }
    
    # Salva mappa dati
    $discoveredData | ConvertTo-Json -Depth 10 | Set-Content $Global:BridgeConfig.DataMapPath
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "📊 RISULTATI SCANSIONE" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  📁 File totali: $($discoveredData.TotalFiles)" -ForegroundColor Cyan
    Write-Host "  🤖 Agenti: $($discoveredData.Agents.Count)" -ForegroundColor Green
    Write-Host "  📱 Social: $($discoveredData.Social.Count)" -ForegroundColor Blue
    Write-Host "  🔧 Tools: $($discoveredData.Tools.Count)" -ForegroundColor Yellow
    Write-Host "  📄 Altri script: $($discoveredData.Scripts.Count)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  💾 Mappa salvata: $($Global:BridgeConfig.DataMapPath)" -ForegroundColor Green
    Write-Host ""
    
    return $discoveredData
}

# ═══════════════════════════════════════════════════════════════════
#  CREAZIONE PONTI
# ═══════════════════════════════════════════════════════════════════

function Create-DataBridges {
    param($DataMap)
    
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║           CREAZIONE PONTI DI LAVORO                       ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    # Crea directory ponti
    if (-not (Test-Path $Global:BridgeConfig.BridgePath)) {
        New-Item -Path $Global:BridgeConfig.BridgePath -ItemType Directory -Force | Out-Null
    }
    
    $bridgesCreated = 0
    
    # PONTE 1: Agenti
    Write-Host "🌉 Ponte AGENTI..." -ForegroundColor Cyan
    $agentBridgePath = Join-Path $Global:BridgeConfig.BridgePath "Agents"
    if (-not (Test-Path $agentBridgePath)) {
        New-Item -Path $agentBridgePath -ItemType Directory -Force | Out-Null
    }
    
    foreach ($agent in $DataMap.Agents) {
        $linkName = $agent.Name
        $linkPath = Join-Path $agentBridgePath $linkName
        
        # Crea symbolic link se non esiste
        if (-not (Test-Path $linkPath)) {
            try {
                New-Item -ItemType SymbolicLink -Path $linkPath -Target $agent.Path -Force -ErrorAction SilentlyContinue | Out-Null
                Write-Host "  ✓ $linkName → $($agent.Path)" -ForegroundColor Green
                $bridgesCreated++
            }
            catch {
                # Se symbolic link fallisce, copia il file
                Copy-Item -Path $agent.Path -Destination $linkPath -Force
                Write-Host "  ✓ $linkName (copiato)" -ForegroundColor Yellow
                $bridgesCreated++
            }
        }
    }
    
    # PONTE 2: Social Media
    Write-Host "`n🌉 Ponte SOCIAL MEDIA..." -ForegroundColor Cyan
    $socialBridgePath = Join-Path $Global:BridgeConfig.BridgePath "Social"
    if (-not (Test-Path $socialBridgePath)) {
        New-Item -Path $socialBridgePath -ItemType Directory -Force | Out-Null
    }
    
    foreach ($social in $DataMap.Social) {
        $linkPath = Join-Path $socialBridgePath $social.Name
        if (-not (Test-Path $linkPath)) {
            Copy-Item -Path $social.Path -Destination $linkPath -Force
            Write-Host "  ✓ $($social.Name)" -ForegroundColor Green
            $bridgesCreated++
        }
    }
    
    # PONTE 3: Tools
    Write-Host "`n🌉 Ponte TOOLS..." -ForegroundColor Cyan
    $toolsBridgePath = Join-Path $Global:BridgeConfig.BridgePath "Tools"
    if (-not (Test-Path $toolsBridgePath)) {
        New-Item -Path $toolsBridgePath -ItemType Directory -Force | Out-Null
    }
    
    foreach ($tool in $DataMap.Tools) {
        $linkPath = Join-Path $toolsBridgePath $tool.Name
        if (-not (Test-Path $linkPath)) {
            Copy-Item -Path $tool.Path -Destination $linkPath -Force
            Write-Host "  ✓ $($tool.Name)" -ForegroundColor Green
            $bridgesCreated++
        }
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "✅ Creati $bridgesCreated ponti di lavoro!" -ForegroundColor Green
    Write-Host "📁 Posizione ponti: $($Global:BridgeConfig.BridgePath)" -ForegroundColor Cyan
    Write-Host ""
    
    # Crea indice ponti
    Create-BridgeIndex -DataMap $DataMap
}

function Create-BridgeIndex {
    param($DataMap)
    
    $indexContent = @"
# GENE1799 - INDICE PONTI DI LAVORO
## Generato: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🤖 AGENTI DISPONIBILI ($($DataMap.Agents.Count))

$($DataMap.Agents | ForEach-Object { "- **$($_.Name)**`n  Path: ``$($_.Path)``" } | Out-String)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📱 SOCIAL MEDIA ($($DataMap.Social.Count))

$($DataMap.Social | ForEach-Object { "- **$($_.Name)**`n  Path: ``$($_.Path)``" } | Out-String)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔧 TOOLS ($($DataMap.Tools.Count))

$($DataMap.Tools | ForEach-Object { "- **$($_.Name)**`n  Path: ``$($_.Path)``" } | Out-String)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📊 STATISTICHE

- **File totali scansionati:** $($DataMap.TotalFiles)
- **Drive scansionati:** D:\, E:\
- **Ultima scansione:** $($DataMap.ScanDate)
- **Ponti attivi:** $($Global:BridgeConfig.BridgePath)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🚀 COMANDI RAPIDI

### Usare un agente:
``````powershell
cd "$($Global:BridgeConfig.BridgePath)\Agents"
.\[nome-agente].ps1
``````

### Usare social media:
``````powershell
cd "$($Global:BridgeConfig.BridgePath)\Social"
.\Gene1799.Social.Instagram.ps1
``````

### Usare tools:
``````powershell
cd "$($Global:BridgeConfig.BridgePath)\Tools"
.\[nome-tool].ps1
``````

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"@
    
    $indexPath = Join-Path $Global:BridgeConfig.BridgePath "INDICE_PONTI.md"
    $indexContent | Set-Content -Path $indexPath -Encoding UTF8
    
    Write-Host "📋 Indice creato: INDICE_PONTI.md" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════════
#  DASHBOARD MIGLIORATA
# ═══════════════════════════════════════════════════════════════════

function Show-ImprovedDashboard {
    Clear-Host
    
    # Carica mappa dati
    if (Test-Path $Global:BridgeConfig.DataMapPath) {
        $dataMap = Get-Content $Global:BridgeConfig.DataMapPath -Raw | ConvertFrom-Json
    }
    else {
        Write-Host "⚠️  Nessuna mappa dati trovata. Esegui prima una scansione!" -ForegroundColor Yellow
        return
    }
    
    # Header migliorato
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                  ║" -ForegroundColor Cyan
    Write-Host "║              GENE1799 - CONTROL CENTER UNIFICATO                ║" -ForegroundColor Cyan
    Write-Host "║                  Bridge System v2.0                              ║" -ForegroundColor Cyan
    Write-Host "║                                                                  ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Status bar
    $totalResources = $dataMap.Agents.Count + $dataMap.Social.Count + $dataMap.Tools.Count
    Write-Host "  ⚡ Sistema Attivo  " -ForegroundColor Green -NoNewline
    Write-Host "│" -ForegroundColor DarkGray -NoNewline
    Write-Host "  📊 $totalResources Risorse Collegate  " -ForegroundColor Cyan -NoNewline
    Write-Host "│" -ForegroundColor DarkGray -NoNewline
    Write-Host "  🔗 Ponti Operativi  " -ForegroundColor Yellow
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    # Sezione AGENTI
    Write-Host "  🤖 AGENTI AI ($($dataMap.Agents.Count) disponibili)" -ForegroundColor Cyan
    Write-Host ""
    
    $agentNum = 1
    foreach ($agent in $dataMap.Agents | Select-Object -First 10) {
        $shortPath = $agent.Path -replace '^D:\\', 'D:\..\' -replace '^E:\\', 'E:\..\' 
        if ($shortPath.Length -gt 50) {
            $shortPath = "..." + $shortPath.Substring($shortPath.Length - 47)
        }
        
        Write-Host "    [$agentNum] " -ForegroundColor Yellow -NoNewline
        Write-Host "$($agent.Name)" -ForegroundColor White -NoNewline
        Write-Host " → $shortPath" -ForegroundColor DarkGray
        $agentNum++
    }
    
    if ($dataMap.Agents.Count -gt 10) {
        Write-Host "    ... e altri $($dataMap.Agents.Count - 10) agenti" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    # Sezione SOCIAL
    Write-Host "  📱 SOCIAL MEDIA ($($dataMap.Social.Count) piattaforme)" -ForegroundColor Blue
    Write-Host ""
    
    $platforms = @{
        Instagram = ($dataMap.Social | Where-Object {$_.Name -like "*Instagram*"}).Count
        TikTok = ($dataMap.Social | Where-Object {$_.Name -like "*TikTok*"}).Count
        YouTube = ($dataMap.Social | Where-Object {$_.Name -like "*YouTube*"}).Count
        X = ($dataMap.Social | Where-Object {$_.Name -like "*X.ps1"}).Count
    }
    
    foreach ($platform in $platforms.Keys) {
        if ($platforms[$platform] -gt 0) {
            Write-Host "    📲 $platform " -ForegroundColor White -NoNewline
            Write-Host "($($platforms[$platform]) script)" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    # Sezione TOOLS
    Write-Host "  🔧 TOOLS & UTILITIES ($($dataMap.Tools.Count) tools)" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($tool in $dataMap.Tools | Select-Object -First 8) {
        Write-Host "    🛠️  $($tool.Name)" -ForegroundColor White
    }
    
    if ($dataMap.Tools.Count -gt 8) {
        Write-Host "    ... e altri $($dataMap.Tools.Count - 8) tools" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    # Menu azioni
    Write-Host "  ⚙️  AZIONI RAPIDE" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "    [1] Apri cartella Agenti        " -ForegroundColor White -NoNewline
    Write-Host "[5] Organizza File" -ForegroundColor White
    Write-Host "    [2] Apri cartella Social        " -ForegroundColor White -NoNewline
    Write-Host "[6] Visualizza Indice Completo" -ForegroundColor White
    Write-Host "    [3] Apri cartella Tools         " -ForegroundColor White -NoNewline
    Write-Host "[7] Riscansione Completa" -ForegroundColor White
    Write-Host "    [4] Status Sistema              " -ForegroundColor White -NoNewline
    Write-Host "[0] Esci" -ForegroundColor White
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host "  Scegli azione"
    
    switch ($choice) {
        "1" { 
            explorer "$($Global:BridgeConfig.BridgePath)\Agents"
            Show-ImprovedDashboard
        }
        "2" { 
            explorer "$($Global:BridgeConfig.BridgePath)\Social"
            Show-ImprovedDashboard
        }
        "3" { 
            explorer "$($Global:BridgeConfig.BridgePath)\Tools"
            Show-ImprovedDashboard
        }
        "4" {
            Show-SystemStatus
            Read-Host "`nPremi Enter per tornare"
            Show-ImprovedDashboard
        }
        "5" {
            Write-Host "`n  🗂️  Organizzazione File..." -ForegroundColor Cyan
            # Chiama file manager se esiste
            $fmPath = Join-Path $Global:BridgeConfig.MainHub "gene1799_file_manager.ps1"
            if (Test-Path $fmPath) {
                & $fmPath -Mode AUTO
            }
            else {
                Write-Host "  ⚠️  File Manager non trovato" -ForegroundColor Yellow
            }
            Read-Host "`nPremi Enter per tornare"
            Show-ImprovedDashboard
        }
        "6" {
            $indexPath = Join-Path $Global:BridgeConfig.BridgePath "INDICE_PONTI.md"
            if (Test-Path $indexPath) {
                notepad $indexPath
            }
            Show-ImprovedDashboard
        }
        "7" {
            Write-Host "`n  🔄 Riscansione in corso..." -ForegroundColor Yellow
            $newMap = Scan-AllGene1799Data
            Create-DataBridges -DataMap $newMap
            Read-Host "`nPremi Enter per tornare"
            Show-ImprovedDashboard
        }
        "0" {
            Write-Host "`n  👋 Arrivederci!`n" -ForegroundColor Cyan
            return
        }
        default {
            Show-ImprovedDashboard
        }
    }
}

function Show-SystemStatus {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  📊 STATUS SISTEMA" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    # Check drives
    Write-Host "  💾 DRIVES:" -ForegroundColor Cyan
    $driveD = Get-PSDrive D -ErrorAction SilentlyContinue
    if ($driveD) {
        $freeGB = [math]::Round($driveD.Free / 1GB, 2)
        Write-Host "    D:\ → $freeGB GB liberi" -ForegroundColor Green
    }
    
    $driveE = Get-PSDrive E -ErrorAction SilentlyContinue
    if ($driveE) {
        $freeGB = [math]::Round($driveE.Free / 1GB, 2)
        Write-Host "    E:\ → $freeGB GB liberi" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "  🔗 PONTI:" -ForegroundColor Cyan
    
    $agentsDir = Join-Path $Global:BridgeConfig.BridgePath "Agents"
    $socialDir = Join-Path $Global:BridgeConfig.BridgePath "Social"
    $toolsDir = Join-Path $Global:BridgeConfig.BridgePath "Tools"
    
    if (Test-Path $agentsDir) {
        $count = (Get-ChildItem $agentsDir).Count
        Write-Host "    Agenti → $count file collegati" -ForegroundColor Green
    }
    
    if (Test-Path $socialDir) {
        $count = (Get-ChildItem $socialDir).Count
        Write-Host "    Social → $count file collegati" -ForegroundColor Green
    }
    
    if (Test-Path $toolsDir) {
        $count = (Get-ChildItem $toolsDir).Count
        Write-Host "    Tools → $count file collegati" -ForegroundColor Green
    }
    
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════

Clear-Host

if ($ScanAll) {
    $dataMap = Scan-AllGene1799Data
    $continue = Read-Host "`nCreare ponti di lavoro? (s/n)"
    if ($continue -eq 's') {
        Create-DataBridges -DataMap $dataMap
    }
}
elseif ($CreateBridges) {
    if (Test-Path $Global:BridgeConfig.DataMapPath) {
        $dataMap = Get-Content $Global:BridgeConfig.DataMapPath -Raw | ConvertFrom-Json
        Create-DataBridges -DataMap $dataMap
    }
    else {
        Write-Host "⚠️  Esegui prima una scansione con -ScanAll" -ForegroundColor Yellow
    }
}
elseif ($ShowDashboard) {
    Show-ImprovedDashboard
}
else {
    # Esecuzione automatica completa
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         GENE1799 UNIVERSAL BRIDGE SYSTEM                  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Scansione automatica
    $dataMap = Scan-AllGene1799Data
    
    # Creazione ponti
    Create-DataBridges -DataMap $dataMap
    
    # Mostra dashboard
    Read-Host "`nPremi Enter per aprire la Dashboard"
    Show-ImprovedDashboard
}
