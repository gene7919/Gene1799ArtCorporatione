$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " FIX COMFYUI PYTHON 3.10 " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Comfy = "C:\SuiteV17\ComfyUI"
$Venv = "$Comfy\.venv"

if (!(Test-Path $Comfy)) {
    throw "Cartella ComfyUI non trovata."
}

Write-Host "Controllo Python 3.10..." -ForegroundColor Yellow
$pyCheck = & py -3.10 --version 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Python 3.10 non trovato. Installa Python 3.10 e rilancia."
}

if (Test-Path $Venv) {
    Write-Host "Rimuovo vecchio venv..." -ForegroundColor Yellow
    Remove-Item $Venv -Recurse -Force
}

Write-Host "Creo nuovo venv con Python 3.10..." -ForegroundColor Yellow
& py -3.10 -m venv $Venv

$PythonExe = "$Venv\Scripts\python.exe"
$PipExe = "$Venv\Scripts\pip.exe"

Write-Host "Aggiorno pip..." -ForegroundColor Yellow
& $PythonExe -m pip install --upgrade pip

Write-Host "Installo requirements ComfyUI..." -ForegroundColor Yellow
& $PipExe install -r "$Comfy\requirements.txt"

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

Set-Content "$Comfy\Launch-ComfyUI.ps1" $Launch -Encoding UTF8

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " COMFYUI FIXATO CON PYTHON 3.10 " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Avvio:"
Write-Host 'powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1"'