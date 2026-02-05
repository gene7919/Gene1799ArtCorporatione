# Gene1799 Hub Manager v9.1
# Auto-gestione completa del backend

$ErrorActionPreference = "Stop"

Write-Host @"

╔════════════════════════════════════════════════════════════════════╗
║        GENE1799 ART CORPORATIONE - HUB MANAGER v9.1              ║
╚════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

function Show-Menu {
    Write-Host ""
    Write-Host "OPZIONI DISPONIBILI:" -ForegroundColor Yellow
    Write-Host "  1. Start Local Server" -ForegroundColor White
    Write-Host "  2. Stop Local Server" -ForegroundColor White
    Write-Host "  3. Restart Local Server" -ForegroundColor White
    Write-Host "  4. Check Status (Local + Production)" -ForegroundColor White
    Write-Host "  5. Deploy to Production" -ForegroundColor White
    Write-Host "  6. View Production Logs" -ForegroundColor White
    Write-Host "  7. Full System Check" -ForegroundColor White
    Write-Host "  8. Exit" -ForegroundColor White
    Write-Host ""
}

function Start-LocalServer {
    Write-Host "🚀 Starting local server..." -ForegroundColor Yellow
    
    $existing = Get-NetTCPConnection -LocalPort 10000 -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "⚠️  Server already running on port 10000" -ForegroundColor Yellow
        return
    }
    
    Set-Location "C:\Gene1799_Complete\backend"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "node server.js"
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
        Write-Host "ℹ️  No server running" -ForegroundColor Cyan
    }
}

function Test-Servers {
    Write-Host "🔍 Checking servers..." -ForegroundColor Yellow
    Write-Host ""
    
    # Local
    try {
        $local = Invoke-RestMethod "http://localhost:10000/api/health" -TimeoutSec 3
        Write-Host "✅ LOCAL:      v$($local.version) | $($local.metrics.agents) agents" -ForegroundColor Green
    } catch {
        Write-Host "❌ LOCAL:      OFFLINE" -ForegroundColor Red
    }
    
    # Production
    try {
        $prod = Invoke-RestMethod "https://gene1799-backend.onrender.com/api/health" -TimeoutSec 5
        Write-Host "✅ PRODUCTION: v$($prod.version) | $($prod.metrics.agents) agents" -ForegroundColor Green
    } catch {
        Write-Host "❌ PRODUCTION: OFFLINE" -ForegroundColor Red
    }
}

function Deploy-ToProduction {
    Write-Host "📤 Deploying to production..." -ForegroundColor Yellow
    
    $message = Read-Host "Commit message"
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = "Update backend $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }
    
    Set-Location "C:\Gene1799_Complete"
    git add backend/
    git commit -m "$message"
    git push origin master
    
    Write-Host "✅ Pushed! Render will deploy in 2-3 minutes" -ForegroundColor Green
}

function Show-ProductionLogs {
    Start-Process "https://dashboard.render.com/web/srv-d620hokhg0os73845100/logs"
}

function Test-FullSystem {
    Write-Host "🔍 Full system check..." -ForegroundColor Cyan
    Write-Host ""
    
    # Files
    Write-Host "FILES:" -ForegroundColor Yellow
    @("backend/package.json", "backend/server.js") | ForEach-Object {
        if (Test-Path $_) {
            Write-Host "  ✅ $_" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "SERVERS:" -ForegroundColor Yellow
    Test-Servers
    
    Write-Host ""
    Write-Host "GIT:" -ForegroundColor Yellow
    $branch = git rev-parse --abbrev-ref HEAD
    $commit = git rev-parse --short HEAD
    Write-Host "  Branch: $branch" -ForegroundColor White
    Write-Host "  Commit: $commit" -ForegroundColor White
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option (1-8)"
    
    switch ($choice) {
        "1" { Start-LocalServer }
        "2" { Stop-LocalServer }
        "3" { Stop-LocalServer; Start-Sleep -Seconds 1; Start-LocalServer }
        "4" { Test-Servers }
        "5" { Deploy-ToProduction }
        "6" { Show-ProductionLogs }
        "7" { Test-FullSystem }
        "8" { Write-Host "👋 Goodbye!" -ForegroundColor Cyan; break }
        default { Write-Host "❌ Invalid option" -ForegroundColor Red }
    }
    
    if ($choice -ne "8") {
        Write-Host ""
        Read-Host "Press ENTER to continue"
    }
    
} while ($choice -ne "8")
