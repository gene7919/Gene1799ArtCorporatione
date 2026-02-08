# GENE1799 LOCAL PROTOTYPE LAUNCHER - PowerShell
# Avvia il sistema completo come prototipo locale

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   GENE1799 LOCAL PROTOTYPE LAUNCHER                   ║" -ForegroundColor Cyan
Write-Host "║   Production-ready system on localhost                ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "[*] Checking prerequisites..." -ForegroundColor Yellow

try {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js not found" -ForegroundColor Red
    exit 1
}

try {
    $npmVersion = npm --version
    Write-Host "[OK] npm $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] npm not found" -ForegroundColor Red
    exit 1
}

# Check directories
$requiredDirs = @("backend\src", "frontend", "telegram-bot")
foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "[OK] $dir found" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] $dir not found" -ForegroundColor Red
        exit 1
    }
}

# Setup environment
Write-Host ""
Write-Host "[*] Setting up environment..." -ForegroundColor Yellow

$envPath = "backend\.env"
$envExamplePath = "backend\.env.example"

if (!(Test-Path $envPath)) {
    if (Test-Path $envExamplePath) {
        Copy-Item $envExamplePath $envPath
        Write-Host "[!] Created backend\.env from template" -ForegroundColor Yellow
        Write-Host "[!] Please configure backend\.env with your credentials" -ForegroundColor Yellow
    }
}

Write-Host "[OK] Environment configured" -ForegroundColor Green

# Install dependencies
Write-Host ""
Write-Host "[*] Installing dependencies..." -ForegroundColor Yellow
npm install 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Launch prototype
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              LAUNCHING PROTOTYPE SYSTEM                ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Starting GENE1799 Local Prototype..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Services starting:" -ForegroundColor Cyan
Write-Host "  📊 Dashboard       → http://localhost:3000" -ForegroundColor Green
Write-Host "  🌐 Web3 dApps      → http://localhost:3000/web3-dapps-dashboard.html" -ForegroundColor Green
Write-Host "  🔌 Backend API     → http://localhost:3001" -ForegroundColor Green
Write-Host "  🤖 Telegram Bot    → Polling active" -ForegroundColor Green
Write-Host ""

# Run prototype launcher
node start-prototype.js
