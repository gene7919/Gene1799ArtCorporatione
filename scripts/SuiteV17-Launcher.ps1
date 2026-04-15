#Requires -Version 5.1
# Suite V17 - Launcher Unificato
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('ControlRoom', 'Terminal', 'Check', 'Install', 'Build', 'All')]
    [string]$Action = 'ControlRoom'
)

$ErrorActionPreference = "Stop"

$Root = "C:\\SuiteV17"
$Colors = @{
    Primary = 'Cyan'; Success = 'Green'; Warning = 'Yellow'; Error = 'Red'; Info = 'White'
}

function Write-Color($Text, $Color = 'Info') {
    Write-Host $Text -ForegroundColor $Colors[$Color]
}

function Show-Header {
    Clear-Host
    Write-Color @"
 ███████╗██╗   ██╗██╗████████╗███████╗██╗  ██╗██╗   ██╗
 ██╔════╝██║   ██║██║╚══██╔══╝██╔════╝██║  ██║██║   ██║
 ███████╗██║   ██║██║   ██║   █████╗  ███████║██║   ██║
 ╚════██║██║   ██║██║   ██║   ██╔══╝  ██╔══██║╚██╗ ██╔╝
 ███████║╚██████╔╝██║   ██║   ███████╗██║  ██║ ╚████╔╝
 ╚══════╝ ╚═════╝ ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝  ╚═══╝   v17.0.0
"@ 'Primary'
    Write-Color "              CONTROL ROOM - Console Unificata" 'Success'
    Write-Color "=" * 57 'Primary'
    Write-Host ""
}

function Start-ControlRoom {
    Write-Color "[INFO] Avvio Control Room..." 'Info'
    Set-Location "$Root\\ElectronApp"
    
    try {
        npm start
    } catch {
        Write-Color "[ERRORE] Impossibile avviare Control Room" 'Error'
        Write-Color $_ 'Error'
    }
}

function Start-Terminal {
    Write-Color "[INFO] Avvio Terminal SuiteV17..." 'Info'
    Start-Process powershell -ArgumentList "-NoExit","-Command","cd $Root; Write-Host '[SuiteV17 Terminal]' -Fore Cyan;npx pm2 status" -WorkingDirectory $Root
}

function Test-Modules {
    Write-Color "[INFO] Verifica moduli in corso..." 'Info'
    Set-Location "$Root\\ElectronApp"
    node scripts\\check-modules.js
}

function Install-All {
    Write-Color "[INFO] Installazione dipendenze..." 'Info'
    
    $modules = @(
        @{ Path = "$Root\\ElectronApp"; Name = 'ElectronApp' },
        @{ Path = "$Root\\TokenModule"; Name = 'TokenModule' },
        @{ Path = "$Root\\BrowserModule"; Name = 'BrowserModule' },
        @{ Path = "$Root\\VideoWorker"; Name = 'VideoWorker' }
    )
    
    foreach ($mod in $modules) {
        Write-Color "[INFO] Installazione $($mod.Name)..." 'Info'
        Set-Location $mod.Path
        npm install | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Color "[OK] $($mod.Name) installato" 'Success'
        } else {
            Write-Color "[ERRORE] $($mod.Name)" 'Error'
        }
    }
    
    Write-Color "`n[OK] Tutti i moduli installati!" 'Success'
}

function Build-Executable {
    Write-Color "[INFO] Build eseguibile in corso..." 'Info'
    Set-Location "$Root\\ElectronApp"
    npm run build:win
    if ($LASTEXITCODE -eq 0) {
        Write-Color "`n[OK] Build completata!\nVerifica in: $Root\\ElectronApp\\dist\" 'Success'
        explorer "$Root\\ElectronApp\\dist"
    } else {
        Write-Color "[ERRORE] Build fallita" 'Error'
    }
}

function Start-AllModules {
    Write-Color "[INFO] Avvio automatico di tutti i moduli..." 'Info'
    Set-Location "$Root\\ElectronApp"
    node scripts\\orchestrator.js start all
}

# Main
Show-Header

switch ($Action) {
    'ControlRoom' { Start-ControlRoom }
    'Terminal' { Start-Terminal }
    'Check' { Test-Modules }
    'Install' { Install-All }
    'Build' { Build-Executable }
    'All' { Start-AllModules }
}
