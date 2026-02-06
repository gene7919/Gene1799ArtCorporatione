# ═══════════════════════════════════════════════════════════
# 🧹 GENE1799 LOG CLEANUP & ARCHIVE
# ═══════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║       GENE1799 LOG CLEANUP UTILITY             ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

$logFile = "D:\Gene1799\Logs\master_orchestrator.log"
$archiveDir = "E:\Gene1799_Data\Logs_Archive"

# Ensure archive directory exists
if (-not (Test-Path $archiveDir)) {
    New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    Write-Host "[CREATE] Archive directory created: $archiveDir" -ForegroundColor Green
}

# Archive current log if it exists
if (Test-Path $logFile) {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $archiveName = "master_orchestrator_$timestamp.log"
    $archivePath = Join-Path $archiveDir $archiveName
    
    Copy-Item $logFile -Destination $archivePath -Force
    Write-Host "[ARCHIVE] Log saved to: $archiveName" -ForegroundColor Cyan
    
    # Show stats
    $lineCount = (Get-Content $logFile | Measure-Object -Line).Lines
    $errorCount = (Get-Content $logFile | Select-String -Pattern "\[ERROR\]" | Measure-Object).Count
    
    Write-Host "[STATS] Total lines: $lineCount" -ForegroundColor Yellow
    Write-Host "[STATS] Error count: $errorCount" -ForegroundColor Yellow
    
    # Clear the log
    Clear-Content $logFile -Force
    Write-Host "[CLEAR] Log file cleared" -ForegroundColor Green
    
    # Write fresh header
    $header = @"
# ═══════════════════════════════════════════════════════════
# GENE1799 MASTER ORCHESTRATOR LOG
# Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ═══════════════════════════════════════════════════════════
"@
    Add-Content -Path $logFile -Value $header
    Write-Host "[INIT] Fresh log initialized" -ForegroundColor Green
    
} else {
    Write-Host "[INFO] No existing log file found" -ForegroundColor Yellow
    
    # Create directories if needed
    $logDir = Split-Path $logFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Create fresh log
    $header = @"
# ═══════════════════════════════════════════════════════════
# GENE1799 MASTER ORCHESTRATOR LOG
# Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ═══════════════════════════════════════════════════════════
"@
    Set-Content -Path $logFile -Value $header
    Write-Host "[CREATE] New log file created" -ForegroundColor Green
}

Write-Host "`n[DONE] Log cleanup complete!`n" -ForegroundColor Green
