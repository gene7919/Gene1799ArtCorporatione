param(
    [string]$action = "menu"
)

$basePath   = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $basePath "config.services.json"

if (-not (Test-Path $configPath)) {
    Write-Host "[ERRORE] Configurazione non trovata: $configPath" -ForegroundColor Red
    exit 1
}

try {
    $configRaw = Get-Content -Path $configPath -Raw -ErrorAction Stop
    $services  = $configRaw | ConvertFrom-Json
}
catch {
    Write-Host "[ERRORE] Impossibile leggere o convertire il file di configurazione: $configPath" -ForegroundColor Red
    exit 1
}

function Start-ServiceModule {
    param(
        [Parameter(Mandatory)]
        [string]$name
    )

    $svc = $services.PSObject.Properties | Where-Object { $_.Name -eq $name } | Select-Object -ExpandProperty Value
    if ($null -eq $svc) {
        Write-Host "[ERRORE] Modulo '$name' non esiste in config.services.json" -ForegroundColor Red
        return
    }

    if (-not $svc.enabled) {
        Write-Host "[INFO] Modulo '$name' è disabilitato (enabled = false)" -ForegroundColor Yellow
        return
    }

    try {
        $svcPathResolved = Resolve-Path -Path (Join-Path $basePath $svc.path) -ErrorAction Stop
        $svcPath = $svcPathResolved.ProviderPath
    }
    catch {
        Write-Host "[ERRORE] Impossibile risolvere il percorso per il modulo '$name': $($svc.path)" -ForegroundColor Red
        return
    }

    Write-Host ">> [GENE1799] Avvio modulo $name in $svcPath" -ForegroundColor Cyan
    
    $escapedCommand = $svc.command -replace '"', '\"'
    $arguments = @("-NoExit", "-Command", "Set-Location -LiteralPath `"$svcPath`"; $escapedCommand")
    
    try {
        Start-Process -FilePath "powershell" -ArgumentList $arguments -WindowStyle Normal
    }
    catch {
        Write-Host "[ERRORE] Impossibile avviare il modulo '$name' con il comando: $($svc.command)" -ForegroundColor Red
    }
}

function Start-AllModules {
    foreach ($property in $services.PSObject.Properties) {
        Start-ServiceModule -name $property.Name
    }
}

function Start-SynapticScribe {
    $planDefault = "C:\Users\marco\Desktop\SuiteV17\agentic\plans\plan_primo_test.json"
    $scriptPath  = "C:\Users\marco\Desktop\SuiteV17\agentic\Synaptic_Scribe.ps1"

    if (-not (Test-Path $scriptPath)) {
        Write-Host "[ERRORE] Script Synaptic_Scribe non trovato: $scriptPath" -ForegroundColor Red
        return
    }
    if (-not (Test-Path $planDefault)) {
        Write-Host "[ERRORE] Piano predefinito non trovato: $planDefault" -ForegroundColor Red
        return
    }
    Write-Host "[GENIO] Avvio Synaptic_Scribe con piano: $planDefault" -ForegroundColor Magenta
    try {
        & $scriptPath -planFile $planDefault
    }
    catch {
        Write-Host "[ERRORE] Errore durante l'esecuzione di Synaptic_Scribe." -ForegroundColor Red
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "===================================" -ForegroundColor Yellow
    Write-Host "  GENE1799 SUITE V17 - CONSOLE ELECTRONIC"
    Write-Host "===================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1) Start FRONTEND  (HTML/JS Commodore16)"
    Write-Host "2) Start BACKEND   (Node/Express API)"
    Write-Host "3) Start BOT       (Telegraf Telegram)"
    Write-Host "4) Start TUTTI I MODULI"
    Write-Host "5) Esegui PIANO SINAPTICO (Synaptic Scribe)"
    Write-Host "q) Esci dalla console"
    Write-Host ""
    $choice = Read-Host "Seleziona"

    switch ($choice) {
        "1" { Start-ServiceModule -name "frontend" }
        "2" { Start-ServiceModule -name "backend" }
        "3" { Start-ServiceModule -name "bot" }
        "4" { Start-AllModules }
        "5" { Start-SynapticScribe }
        "q" { exit 0 }
        default {
            Write-Host "Scelta non valida." -ForegroundColor Red
        }
    }

    Write-Host ""
    Read-Host "Premi INVIO per tornare al menu"
    Show-Menu
}

switch ($action.ToLowerInvariant()) {
    "menu"      { Show-Menu }
    "start-all" { Start-AllModules }
    default     { Show-Menu }
}
