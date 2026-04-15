param(
    [string] $NodePath = "node"
)

$root = "C:\SuiteV17"
$electronDir = Join-Path $root "ElectronApp"

Write-Host ">> GENE1799/SuiteV17 – AI scaffold Electron" -ForegroundColor Cyan

if (-not (Test-Path $root)) {
    Write-Error "Cartella $root non trovata."
    exit 1
}

if (-not (Test-Path $electronDir)) {
    New-Item -ItemType Directory -Path $electronDir | Out-Null
    Write-Host "Creata cartella ElectronApp." -ForegroundColor Green
}

$aiScript = Join-Path $root "ai_scaffold.js"
if (-not (Test-Path $aiScript)) {
    Write-Error "ai_scaffold.js non trovato in $root. Copia prima lo script Node."
    exit 1
}

# 1) Lancia Node per generare main.js + index.html
Write-Host ">> Lancio Node per generare UI..." -ForegroundColor Yellow
& $NodePath $aiScript
if ($LASTEXITCODE -ne 0) {
    Write-Error "Errore durante l'esecuzione di ai_scaffold.js"
    exit 1
}

# 2) Inizializza package.json minimo per ElectronApp (se manca)
$pkgPath = Join-Path $electronDir "package.json"
if (-not (Test-Path $pkgPath)) {
    Write-Host ">> Creo package.json base per ElectronApp..." -ForegroundColor Yellow
    $pkg = @{
        name = "suitev17-electron"
        version = "1.0.0"
        main = "main.js"
        scripts = @{
            start = "electron ."
        }
    }
    $pkg | ConvertTo-Json -Depth 5 | Out-File $pkgPath -Encoding utf8
} else {
    $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
    $pkg.main = "main.js"
    if (-not $pkg.scripts) { $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue @{} }
    $pkg.scripts.start = "electron ."
    $pkg | ConvertTo-Json -Depth 5 | Out-File $pkgPath -Encoding utf8
}

# 3) Installa Electron (se non già presente)
Write-Host ">> Installo/aggiorno Electron (npm i electron@latest --save-dev)..." -ForegroundColor Yellow
Push-Location $electronDir
npm install electron@latest --save-dev
Pop-Location

Write-Host ">> FATTO. Per avviare l'app Electron UI:" -ForegroundColor Cyan
Write-Host "   cd `"$electronDir`"" -ForegroundColor Green
Write-Host "   npm start" -ForegroundColor Green
