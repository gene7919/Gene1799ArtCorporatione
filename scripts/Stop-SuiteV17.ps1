# ============================================
# Stop-SuiteV17.ps1
# Spegnimento completo: PM2 + BrowserModule + porte
# ============================================

$ErrorActionPreference = "Stop"

Write-Host "`n[SUITEV17] Arresto orchestrato..." -ForegroundColor Cyan

# --------------------------------------------
# 1) Ferma i processi gestiti da PM2
# --------------------------------------------

Write-Host "[SUITEV17] pm2 stop all..." -ForegroundColor Yellow
try {
  pm2 stop all 2>$null
  pm2 delete all 2>$null
  Write-Host "[SUITEV17] PM2: tutti i processi fermati e rimossi." -ForegroundColor Green
} catch {
  Write-Host "[SUITEV17] PM2: errore nello stop/delete (forse PM2 non è in esecuzione)." -ForegroundColor DarkYellow
}

# --------------------------------------------
# 2) Chiudi i Node/nodemon sulle porte note
#    (8090, 8091, 3000, 8095, 8096)
# --------------------------------------------

$ports = @(8090, 8091, 3000, 8095, 8096)
$killPids = @()

foreach ($p in $ports) {
  $lines = netstat -ano | Select-String ":$p" 2>$null
  foreach ($line in $lines) {
    $parts = ($line.ToString() -split "\s+") | Where-Object { $_ -ne "" }
    $pidStr = $parts[-1]
    if ($pidStr -match '^\d+$') {
      $procId = [int]$pidStr
      if ($procId -ne 0) { $killPids += $procId }  # ignora PID 0
    }
  }
}

$killPids = $killPids | Sort-Object -Unique

if ($killPids.Count -gt 0) {
  Write-Host "[SUITEV17] Chiudo PID attivi sulle porte $($ports -join ', '): $($killPids -join ', ')" -ForegroundColor Yellow
  foreach ($kpid in $killPids) {
    try {
      taskkill /PID $kpid /F | Out-Null
      Write-Host "   - Terminato PID $kpid" -ForegroundColor DarkYellow
    } catch {
      Write-Host ("   - Errore nel terminare PID {0}: {1}" -f $kpid, $_.Exception.Message) -ForegroundColor Red
    }
  }
} else {
  Write-Host "[SUITEV17] Nessun processo attivo su $($ports -join '/')." -ForegroundColor Green
}

Write-Host "`n[SUITEV17] Arresto completo eseguito." -ForegroundColor Cyan
