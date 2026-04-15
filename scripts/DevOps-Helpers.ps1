function Get-V17Pm2List {
  param(
    [string]$Pm2Home = "C:\pm2\.pm2"
  )
  $env:PM2_HOME = $Pm2Home
  pm2 jlist 2>$null | ConvertFrom-Json
}

function New-V17Snapshot {
  param(
    [string]$OutputDir = "C:\SuiteV17\logs\snapshots",
    [string]$Pm2Home   = "C:\pm2\.pm2"
  )

  New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $snapDir = Join-Path $OutputDir "snapshot_$ts"
  New-Item -ItemType Directory -Force -Path $snapDir | Out-Null

  # stato agenti/workspaces/tools
  Copy-Item "C:\SuiteV17\config\agents\agents.json"  "$snapDir\agents.json" -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path "$snapDir\workspaces" | Out-Null
  Copy-Item "C:\SuiteV17\config\workspaces\*.json"   "$snapDir\workspaces\" -ErrorAction SilentlyContinue
  Copy-Item "C:\SuiteV17\config\tools\tools.json"    "$snapDir\tools.json"  -ErrorAction SilentlyContinue

  # stato PM2
  $env:PM2_HOME = $Pm2Home
  pm2 jlist 2>$null | Out-File -FilePath "$snapDir\pm2_jlist.json" -Encoding UTF8
  pm2 ls          | Out-File -FilePath "$snapDir\pm2_ls.txt"       -Encoding UTF8

  Write-Host "[SUITEV17] Snapshot creato in $snapDir" -ForegroundColor Green
}

function Start-V17NightRun {
  param(
    [string]$Pm2Home = "C:\pm2\.pm2"
  )

  $env:PM2_HOME = $Pm2Home
  Write-Host "`n[SUITEV17] Night-run: avvio orchestrato + pm2 logs..." -ForegroundColor Cyan

  & "C:\Start-SuiteV17.ps1"

  Write-Host "[SUITEV17] Streaming pm2 logs (CTRL+C per fermare)." -ForegroundColor Yellow
  pm2 logs
}
