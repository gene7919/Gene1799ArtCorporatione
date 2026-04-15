Write-Host ""
Write-Host "GENESIS SUITE V17 AVVIO COMPLETO" -ForegroundColor Cyan
Write-Host ""

# Encoding corretto
chcp 65001 > $null

# Porta AI
$ports = @(3000,8090,8091)

foreach ($p in $ports) {
    $process = Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue
    if ($process) {
        $pid = $process.OwningProcess
        Write-Host "Chiudo processo su porta $p PID $pid"
        Stop-Process -Id $pid -Force
    }
}

Write-Host ""
Write-Host "Avvio PM2..."
pm2 resurrect

Start-Sleep 2

Write-Host ""
Write-Host "Stato servizi:"
pm2 status

Write-Host ""
Write-Host "AI attiva su:"
Write-Host "RAG CORE  -> http://localhost:8090"
Write-Host "RAG BRIDGE-> http://localhost:8091"
Write-Host "WEB PANEL -> http://localhost:3000"
Write-Host ""