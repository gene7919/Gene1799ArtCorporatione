$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " REINSTALL COMFYUI CORE " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17\ComfyUI"
$Temp = "C:\SuiteV17\_ComfyUI_Core_Temp"

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git non trovato nel PATH."
}

if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    throw "python non trovato nel PATH."
}

if (Test-Path $Temp) {
    Remove-Item $Temp -Recurse -Force
}

Write-Host "Clonazione temporanea ComfyUI..." -ForegroundColor Yellow
git clone https://github.com/comfy-org/ComfyUI.git $Temp

if (!(Test-Path "$Temp\main.py")) {
    throw "Clone ComfyUI fallito: main.py non trovato nella temp."
}

Write-Host "Copio i file core in C:\SuiteV17\ComfyUI ..." -ForegroundColor Yellow

Get-ChildItem $Temp -Force | ForEach-Object {
    $name = $_.Name
    if ($name -ne "custom_nodes") {
        Copy-Item $_.FullName $Root -Recurse -Force
    }
}

Remove-Item $Temp -Recurse -Force

$Venv = Join-Path $Root ".venv"
$PythonExe = Join-Path $Venv "Scripts\python.exe"
$PipExe = Join-Path $Venv "Scripts\pip.exe"

if (!(Test-Path $PythonExe)) {
    Write-Host "Creo virtualenv..." -ForegroundColor Yellow
    python -m venv $Venv
}

Write-Host "Aggiorno pip..." -ForegroundColor Yellow
& $PythonExe -m pip install --upgrade pip

Write-Host "Installo requirements..." -ForegroundColor Yellow
& $PipExe install -r "$Root\requirements.txt"

$Launch = @'
$ErrorActionPreference = "Stop"
Set-Location "C:\SuiteV17\ComfyUI"

if (!(Test-Path ".\main.py")) {
    throw "main.py non trovato in C:\SuiteV17\ComfyUI"
}

if (!(Test-Path ".\.venv\Scripts\python.exe")) {
    throw "python venv non trovato in C:\SuiteV17\ComfyUI\.venv"
}

$env:CUDA_VISIBLE_DEVICES = "0"
$env:FORCE_CUDA = "1"
$env:HF_HUB_DISABLE_TELEMETRY = "1"

& ".\.venv\Scripts\python.exe" ".\main.py" --listen 127.0.0.1 --port 8188
'@

Set-Content "C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1" $Launch -Encoding UTF8

$Desktop = [Environment]::GetFolderPath("Desktop")
Set-Content "$Desktop\ComfyUI.bat" @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1"
'@ -Encoding ASCII

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " COMFYUI CORE REINSTALLATO " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Controlla ora questi file:"
Write-Host " - C:\SuiteV17\ComfyUI\main.py"
Write-Host " - C:\SuiteV17\ComfyUI\requirements.txt"
Write-Host ""
Write-Host "Avvio:"
Write-Host 'powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1"'