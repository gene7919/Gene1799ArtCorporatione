$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " FIX COMFYUI STRUCTURE (DEFINITIVO) "
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17\ComfyUI"
$Nested = Join-Path $Root "ComfyUI"

# -------------------------
# CHECK SE STRUTTURA ANNIDATA
# -------------------------
if (Test-Path "$Nested\main.py") {

    Write-Host "Struttura annidata trovata. Correzione..." -ForegroundColor Yellow

    # copia tutto fuori
    Get-ChildItem $Nested -Force | ForEach-Object {
        Move-Item $_.FullName $Root -Force
    }

    # elimina cartella annidata
    Remove-Item $Nested -Recurse -Force

    Write-Host "Struttura corretta." -ForegroundColor Green

} else {
    Write-Host "Struttura già corretta." -ForegroundColor Green
}

# -------------------------
# FIX VENV
# -------------------------
$Venv = Join-Path $Root ".venv"

if (!(Test-Path "$Venv\Scripts\python.exe")) {
    Write-Host "Reinstallo venv..." -ForegroundColor Yellow
    python -m venv $Venv
}

$Python = "$Venv\Scripts\python.exe"
$Pip = "$Venv\Scripts\pip.exe"

Write-Host "Installo requirements..." -ForegroundColor Yellow
& $Python -m pip install --upgrade pip
& $Pip install -r "$Root\requirements.txt"

# -------------------------
# FIX LAUNCHER
# -------------------------
$Launch = @'
$ErrorActionPreference = "Stop"
Set-Location "C:\SuiteV17\ComfyUI"

$env:CUDA_VISIBLE_DEVICES = "0"
$env:FORCE_CUDA = "1"

& ".\.venv\Scripts\python.exe" ".\main.py" --listen 127.0.0.1 --port 8188
'@

Set-Content "C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1" $Launch -Encoding UTF8

# -------------------------
# DESKTOP
# -------------------------
$Desktop = [Environment]::GetFolderPath("Desktop")

Set-Content "$Desktop\ComfyUI.bat" @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1"
'@ -Encoding ASCII

# -------------------------
# TEST
# -------------------------
Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " COMFYUI FIX COMPLETATO " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Avvia ora:"
Write-Host "ComfyUI.bat"