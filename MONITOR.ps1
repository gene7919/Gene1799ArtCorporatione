# Gene1799 Backend Monitor v9.1
# Usage: .\MONITOR.ps1

$local = "http://localhost:10000"
$prod = "https://gene1799-backend.onrender.com"

Write-Host @"

╔════════════════════════════════════════════════════════════════════╗
║         GENE1799 BACKEND MONITOR - Real-time Status               ║
╚════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

function Test-Server {
    param($url, $name)
    
    try {
        $response = Invoke-RestMethod "$url/api/health" -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ $name" -ForegroundColor Green -NoNewline
        Write-Host " | v$($response.version) | $($response.metrics.agents) agents | $($response.metrics.requests) req" -ForegroundColor White
        return $true
    } catch {
        Write-Host "❌ $name" -ForegroundColor Red -NoNewline
        Write-Host " | OFFLINE" -ForegroundColor DarkGray
        return $false
    }
}

Write-Host "Checking servers..." -ForegroundColor Yellow
Write-Host ""

$localStatus = Test-Server $local "Local (10000)"
$prodStatus = Test-Server $prod "Production"

Write-Host ""

if ($localStatus -and $prodStatus) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "✅ ALL SYSTEMS OPERATIONAL" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
} elseif ($localStatus) {
    Write-Host "⚠️  Local OK, Production DOWN" -ForegroundColor Yellow
} elseif ($prodStatus) {
    Write-Host "⚠️  Production OK, Local DOWN" -ForegroundColor Yellow
} else {
    Write-Host "❌ ALL SYSTEMS DOWN" -ForegroundColor Red
}

Write-Host ""
