$ErrorActionPreference = "Stop"

$backendScript = Join-Path $PSScriptRoot "start-backend.ps1"
$electronScript = Join-Path $PSScriptRoot "start-electron.ps1"

Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$backendScript`""
Start-Sleep -Seconds 6
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$electronScript`""
