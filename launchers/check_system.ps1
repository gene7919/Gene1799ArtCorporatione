# Script per verificare lo stato di tutte le app
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '    SUITEV17 - CONTROLLO SISTEMA' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

Write-Host 'VERIFICA SERVIZI:' -ForegroundColor Yellow
Write-Host '-----------------' -ForegroundColor Yellow

# Verifica Node.js
$nodeVersion = node --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Node.js: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host 'Node.js: NON INSTALLATO' -ForegroundColor Red
}

# Verifica npm
$npmVersion = npm --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "npm: v$npmVersion" -ForegroundColor Green
} else {
    Write-Host 'npm: NON INSTALLATO' -ForegroundColor Red
}

# Verifica Python
$pythonVersion = python --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Python: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host 'Python: NON INSTALLATO' -ForegroundColor Red
}

# Verifica Electron
$electronVersion = npm list -g electron 2>$null | Select-String 'electron@'
if ($electronVersion) {
    Write-Host "Electron: $electronVersion" -ForegroundColor Green
} else {
    Write-Host 'Electron: NON INSTALLATO GLOBALMENTE' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'VERIFICA APPLICAZIONI:' -ForegroundColor Yellow
Write-Host '---------------------' -ForegroundColor Yellow

$apps = @(
    'electron-app',
    'Gene1799DesktopApp',
    'Gene1799ArtCorporationeHubElectron',
    'GenStudioApp',
    'OpsControlApp',
    'SUITEV17_App',
    'AIHub',
    'ComfyUI'
)

foreach ($app in $apps) {
    $path = "C:\SuiteV17\$app"
    if (Test-Path $path) {
        $nodeModules = "$path\node_modules"
        if (Test-Path $nodeModules) {
            $count = (Get-ChildItem $nodeModules -Directory -ErrorAction SilentlyContinue).Count
            Write-Host "$app : OK ($count moduli)" -ForegroundColor Green
        } else {
            Write-Host "$app : MANCANNO MODULI" -ForegroundColor Yellow
        }
    } else {
        Write-Host "$app : NON TROVATO" -ForegroundColor Red
    }
}

Write-Host ''
Write-Host 'VERIFICA PLUGIN ELECTRON:' -ForegroundColor Yellow
Write-Host '------------------------' -ForegroundColor Yellow

$electronPlugins = @('electron-store', 'electron-updater', 'electron-context-menu')
$electronApp = 'C:\SuiteV17\electron-app\node_modules'

foreach ($plugin in $electronPlugins) {
    if (Test-Path "$electronApp\$plugin") {
        Write-Host "$plugin : INSTALLATO" -ForegroundColor Green
    } else {
        Write-Host "$plugin : MANCANTE" -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '    PREMI UN TASTO PER USCIRE' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
