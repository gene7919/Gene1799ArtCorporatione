# ╔══════════════════════════════════════════════════════════════════╗
# ║  GENE1799 MASTER ORCHESTRATOR - FIXED VERSION                   ║
# ║  - Gestione sicura righe vuote                                   ║
# ║  - Mode DRYRUN/LIVE completo                                     ║
# ║  - Logging migliorato                                            ║
# ╚══════════════════════════════════════════════════════════════════╝

# ========== CONFIGURAZIONE ==========
$Mode = "DRYRUN"   # DRYRUN | LIVE
$DROOT = "D:\Gene1799"
$EROOT = "E:\Gene1799_Data"
$LOGDIR = "$DROOT\Logs"
$LOG = "$LOGDIR\master_orchestrator.log"

# ========== SETUP LOGGING ==========
New-Item -ItemType Directory -Force -Path $LOGDIR | Out-Null
"=== MODE: $Mode | START $(Get-Date) ===" | Out-File $LOG -Encoding UTF8

function Log($m) { 
    if (-not [string]::IsNullOrWhiteSpace($m)) {
        $m | Out-File $LOG -Append -Encoding UTF8
    }
}

# ========== MODULES LOADED ==========
$LoadedModules = (Get-Module).Name
Log "Loaded HUB Modules: $($LoadedModules -join ', ')"

# ========== SAFE ACTION FUNCTION ==========
function Safe-Action {
    param(
        [string]$Action,
        [string]$From,
        [string]$To
    )
    
    # Verifica parametri non vuoti
    if ([string]::IsNullOrWhiteSpace($From) -or [string]::IsNullOrWhiteSpace($To)) {
        Log "[ERROR] Safe-Action chiamata con parametri vuoti: From='$From', To='$To'"
        return
    }
    
    # Verifica che il file sorgente esista
    if (-not (Test-Path $From)) {
        Log "[WARN] File sorgente non esiste: $From"
        return
    }
    
    if ($Mode -eq "DRYRUN") {
        Log "[DRYRUN] $Action :: $From -> $To"
    } 
    else {
        try {
            # Crea la directory di destinazione se non esiste
            $destDir = Split-Path -Parent $To
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                Log "[LIVE] Directory creata: $destDir"
            }
            
            # Verifica se il file di destinazione esiste già
            if (-not (Test-Path $To)) {
                Move-Item $From $To -Force -ErrorAction Stop
                Log "[LIVE] $Action :: $From -> $To"
            }
            else {
                Log "[SKIP] File già esistente: $To"
            }
        }
        catch {
            Log "[ERROR] $Action FAILED :: $From -> $To | Error: $($_.Exception.Message)"
        }
    }
}

# ========== DIRECTORY STRUCTURE SETUP ==========
$Directories = @(
    "$DROOT\Modules",
    "$DROOT\Core",
    "$DROOT\Config",
    "$EROOT\Logs_Archive"
)

foreach ($dir in $Directories) {
    if ([string]::IsNullOrWhiteSpace($dir)) {
        continue
    }
    
    if (-not (Test-Path $dir)) {
        if ($Mode -eq "DRYRUN") {
            Log "[DRYRUN] CREATE DIR :: $dir"
        }
        else {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Log "[LIVE] CREATE DIR :: $dir"
        }
    }
}

# ========== FILE SCANNING & ORGANIZATION ==========
$ScanRoots = @("D:\", "E:\") | Where-Object { Test-Path $_ }

Log "Scanning roots: $($ScanRoots -join ', ')"

$FileCount = @{
    Module = 0
    Core = 0
    Config = 0
    Log = 0
    Skipped = 0
}

Get-ChildItem $ScanRoots -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    
    # Skip se fullname è vuoto
    if ([string]::IsNullOrWhiteSpace($_.FullName)) {
        return
    }
    
    # Skip system directories
    if ($_.FullName -match "\\Windows\\|\\Program Files|\\AppData\\|\\ProgramData\\") { 
        $FileCount.Skipped++
        return 
    }
    
    # Skip se già nella destinazione corretta
    if ($_.FullName -like "$DROOT\*" -or $_.FullName -like "$EROOT\*") {
        return
    }
    
    switch ($_.Extension.ToLower()) {
        ".ps1" { 
            Safe-Action "MODULE" $_.FullName "$DROOT\Modules\$($_.Name)"
            $FileCount.Module++
        }
        ".psm1" { 
            Safe-Action "MODULE" $_.FullName "$DROOT\Modules\$($_.Name)"
            $FileCount.Module++
        }
        ".psd1" { 
            Safe-Action "CORE" $_.FullName "$DROOT\Core\$($_.Name)"
            $FileCount.Core++
        }
        ".json" { 
            Safe-Action "CONFIG" $_.FullName "$DROOT\Config\$($_.Name)"
            $FileCount.Config++
        }
        ".log" { 
            Safe-Action "ARCHIVE LOG" $_.FullName "$EROOT\Logs_Archive\$($_.Name)"
            $FileCount.Log++
        }
    }
}

# ========== ASSETS MANAGEMENT (FIXED) ==========
# Se hai una lista di asset da gestire, usa questo blocco sicuro:
<#
$Assets = @(
    "D:\SomeAsset\file1.txt",
    "D:\SomeAsset\file2.txt"
    # Aggiungi altri asset qui
)

$AssetsTarget = "$EROOT\Assets"

# Crea directory assets se non esiste
if (-not (Test-Path $AssetsTarget)) {
    if ($Mode -eq "DRYRUN") {
        Log "[DRYRUN] CREATE ASSETS DIR :: $AssetsTarget"
    }
    else {
        New-Item -ItemType Directory -Path $AssetsTarget -Force | Out-Null
        Log "[LIVE] CREATE ASSETS DIR :: $AssetsTarget"
    }
}

foreach ($asset in $Assets) {
    
    # BLOCCA RIGHE VUOTE
    if ([string]::IsNullOrWhiteSpace($asset)) {
        continue
    }
    
    # Verifica esistenza file
    if (-not (Test-Path $asset)) {
        Log "[WARN] Asset non trovato: $asset"
        continue
    }
    
    $assetName = Split-Path -Leaf $asset
    $destination = Join-Path $AssetsTarget $assetName
    
    if ($Mode -eq "DRYRUN") {
        Log "[DRYRUN] ASSET :: $asset -> $destination"
    }
    else {
        try {
            Copy-Item -Path $asset -Destination $destination -Recurse -Force -ErrorAction Stop
            Log "[LIVE] ASSET COPIATO :: $asset -> $destination"
        }
        catch {
            Log "[ERROR] ASSET COPY FAILED :: $asset | Error: $($_.Exception.Message)"
        }
    }
}
#>

# ========== SUMMARY ==========
Log ""
Log "=== SUMMARY ==="
Log "Module files: $($FileCount.Module)"
Log "Core files: $($FileCount.Core)"
Log "Config files: $($FileCount.Config)"
Log "Log files: $($FileCount.Log)"
Log "Skipped files: $($FileCount.Skipped)"
Log "=== END $(Get-Date) ==="

# ========== CONSOLE OUTPUT ==========
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GENE1799 MASTER ORCHESTRATOR - COMPLETED          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Mode:     $Mode" -ForegroundColor $(if ($Mode -eq "DRYRUN") { "Yellow" } else { "Green" })
Write-Host "  Modules:  $($FileCount.Module) files" -ForegroundColor White
Write-Host "  Core:     $($FileCount.Core) files" -ForegroundColor White
Write-Host "  Config:   $($FileCount.Config) files" -ForegroundColor White
Write-Host "  Logs:     $($FileCount.Log) files" -ForegroundColor White
Write-Host "  Skipped:  $($FileCount.Skipped) files" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Log:      $LOG" -ForegroundColor Cyan
Write-Host ""

if ($Mode -eq "DRYRUN") {
    Write-Host "✔ Orchestrator completato in DRYRUN mode" -ForegroundColor Yellow
    Write-Host "  Per eseguire le operazioni reali, cambia Mode in 'LIVE'" -ForegroundColor Yellow
}
else {
    Write-Host "✔ Orchestrator completato in LIVE mode" -ForegroundColor Green
}
Write-Host ""
