# GENE1799 Hub Manager v9.2
# Central control system for Gene1799 Art Corporatione

$ErrorActionPreference = "SilentlyContinue"

Write-Host @"

╔════════════════════════════════════════════════════════════════════╗
║        GENE1799 ART CORPORATIONE - HUB MANAGER v9.2              ║
╚════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

function Show-Menu {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "ACTIONS" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. 🚀 Start Local Server" -ForegroundColor White
    Write-Host "  2. 🛑 Stop Local Server" -ForegroundColor White
    Write-Host "  3. 🔄 Restart Local Server" -ForegroundColor White
    Write-Host "  4. 📊 Check Status (Local + Production)" -ForegroundColor White
    Write-Host "  5. 🧪 Run Supreme Monitor" -ForegroundColor White
    Write-Host "  6. 📤 Deploy to Production" -ForegroundColor White
    Write-Host "  7. 🔍 View Production Logs" -ForegroundColor White
    Write-Host "  8. 📝 View Local Logs" -ForegroundColor White
    Write-Host "  9. 🌐 Open Production Dashboard" -ForegroundColor White
    Write-Host "  0. 👋 Exit" -ForegroundColor White
    Write-Host ""
}

function Start-LocalServer {
    Write-Host "🚀 Starting local server..." -ForegroundColor Yellow
    
    $existing = Get-NetTCPConnection -LocalPort 10000 -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "⚠️  Server already running on port 10000" -ForegroundColor Yellow
        return
    }
    
    $backendPath = "C:\Gene1799_Complete\backend"
    if (-not (Test-Path "$backendPath\server.js")) {
        Write-Host "❌ server.js not found in $backendPath" -ForegroundColor Red
        return
    }
    
    Set-Location $backendPath
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; node server.js"
    Start-Sleep -Seconds 2
    
    Write-Host "✅ Server started on http://localhost:10000" -ForegroundColor Green
}

function Stop-LocalServer {
    Write-Host "🛑 Stopping local server..." -ForegroundColor Yellow
    
    $process = Get-NetTCPConnection -LocalPort 10000 -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty OwningProcess -Unique
    
    if ($process) {
        Stop-Process -Id $process -Force
        Write-Host "✅ Server stopped (PID: $process)" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  No server running on port 10000" -ForegroundColor Cyan
    }
}

function Test-Servers {
    Write-Host "🔍 Checking servers..." -ForegroundColor Yellow
    Write-Host ""
    
    # Local
    try {
        $local = Invoke-RestMethod "http://localhost:10000/api/health" -TimeoutSec 3
        Write-Host "✅ LOCAL:      v$($local.version) | $($local.metrics.agents) agents | $($local.metrics.requests) req" -ForegroundColor Green
    } catch {
        Write-Host "❌ LOCAL:      OFFLINE" -ForegroundColor Red
    }
    
    # Production
    try {
        $prod = Invoke-RestMethod "https://gene1799-backend.onrender.com/api/health" -TimeoutSec 5
        Write-Host "✅ PRODUCTION: v$($prod.version) | $($prod.metrics.agents) agents | $($prod.metrics.requests) req" -ForegroundColor Green
    } catch {
        Write-Host "❌ PRODUCTION: OFFLINE or DEPLOYING" -ForegroundColor Yellow
    }
}

function Deploy-ToProduction {
    Write-Host "📤 Deploying to production..." -ForegroundColor Yellow
    Write-Host ""
    
    Set-Location "C:\Gene1799_Complete"
    
    $message = Read-Host "Commit message (press ENTER for auto)"
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = "Update backend $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }
    
    Write-Host "📝 Committing changes..." -ForegroundColor Cyan
    git add backend/
    git commit -m "$message"
    
    Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Cyan
    git push origin master
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Pushed successfully!" -ForegroundColor Green
        Write-Host "⏳ Render will auto-deploy in 2-3 minutes" -ForegroundColor Cyan
        Write-Host "🔍 Monitor: https://dashboard.render.com/web/srv-d620hokhg0os73845100/logs" -ForegroundColor White
    } else {
        Write-Host "❌ Push failed!" -ForegroundColor Red
    }
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select action (0-9)"
    Write-Host ""
    
    switch ($choice) {
        "1" { Start-LocalServer }
        "2" { Stop-LocalServer }
        "3" { Stop-LocalServer; Start-Sleep -Seconds 1; Start-LocalServer }
        "4" { Test-Servers }
        "5" { & ".\GENE1799-SUPREME-MONITOR.ps1" }
        "6" { Deploy-ToProduction }
        "7" { Start-Process "https://dashboard.render.com/web/srv-d620hokhg0os73845100/logs" }
        "8" { Write-Host "📝 Local logs in terminal where server is running" -ForegroundColor Cyan }
        "9" { Start-Process "https://gene1799-backend.onrender.com/api/health" }
        "0" { Write-Host "👋 Goodbye!" -ForegroundColor Cyan; break }
        default { Write-Host "❌ Invalid option. Try again." -ForegroundColor Red }
    }
    
    if ($choice -ne "0") {
        Write-Host ""
        Read-Host "Press ENTER to continue"
        Clear-Host
    }
    
} while ($choice -ne "0")
