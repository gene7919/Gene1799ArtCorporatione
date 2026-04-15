#Requires -Version 5.1
# Setup completo Media Studio AI

$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SUITE V17 - Media Studio AI Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$Root = "C:\SuiteV17"
$ModelsDir = "$Root\ElectronApp\models"

# Verifica Python
Write-Host "[1/5] Verifica Python..." -ForegroundColor Yellow
try {
    $pyVersion = python --version 2>&1
    Write-Host "    $pyVersion" -ForegroundColor Green
} catch {
    Write-Host "    ERRORE: Python non trovato. Installa da python.org" -ForegroundColor Red
    exit 1
}

# Crea cartelle
Write-Host "[2/5] Creazione struttura..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$ModelsDir" | Out-Null
New-Item -ItemType Directory -Force -Path "$Root\AIMedia\generated" | Out-Null
New-Item -ItemType Directory -Force -Path "$Root\Outputs" | Out-Null
New-Item -ItemType Directory -Force -Path "$Root\tmp" | Out-Null
Write-Host "    OK" -ForegroundColor Green

# Installa MusicGen
Write-Host "[3/5] Installazione MusicGen (Meta AI)..." -ForegroundColor Yellow
Write-Host "    Questo potrebbe richiedere alcuni minuti..." -ForegroundColor Gray
$musicGenInstalled = $false
try {
    pip show audiocraft 2>&1 | Out-Null
    $musicGenInstalled = $true
    Write-Host "    MusicGen già installato" -ForegroundColor Green
} catch {
    try {
        pip install -U audiocraft torch torchaudio --quiet 2>&1 | Out-Null
        Write-Host "    MusicGen installato" -ForegroundColor Green
        $musicGenInstalled = $true
    } catch {
        Write-Host "    Warning: Problema installazione MusicGen" -ForegroundColor Yellow
    }
}

# Real-ESRGAN
Write-Host "[4/5] Download Real-ESRGAN..." -ForegroundColor Yellow
if (Test-Path "$ModelsDir\Real-ESRGAN") {
    Write-Host "    Real-ESRGAN già presente" -ForegroundColor Green
} else {
    try {
        git clone https://github.com/xinntao/Real-ESRGAN.git "$ModelsDir\Real-ESRGAN" 2>&1 | Out-Null
        Set-Location "$ModelsDir\Real-ESRGAN"
        pip install -r requirements.txt --quiet 2>&1 | Out-Null
        Write-Host "    Real-ESRGAN pronto" -ForegroundColor Green
    } catch {
        Write-Host "    ERRORE: Impossibile scaricare Real-ESRGAN" -ForegroundColor Red
    }
}

# RIFE
Write-Host "[5/5] Download RIFE..." -ForegroundColor Yellow
if (Test-Path "$ModelsDir\arxiv2020-RIFE") {
    Write-Host "    RIFE già presente" -ForegroundColor Green
} else {
    try {
        git clone https://github.com/hzwer/arxiv2020-RIFE.git "$ModelsDir\arxiv2020-RIFE" 2>&1 | Out-Null
        Set-Location "$ModelsDir\arxiv2020-RIFE"
        pip install -r requirements.txt --quiet 2>&1 | Out-Null
        Write-Host "    RIFE pronto" -ForegroundColor Green
    } catch {
        Write-Host "    ERRORE: Impossibile scaricare RIFE" -ForegroundColor Red
    }
}

Set-Location $Root

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  SETUP COMPLETATO!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Ora puoi avviare SuiteV17 Control Room:" -ForegroundColor Cyan
Write-Host "  cd C:\SuiteV17\ElectronApp" -ForegroundColor White
Write-Host "  npm start" -ForegroundColor White
Write-Host ""
Write-Host "E cliccare su MEDIA STUDIO 4K" -ForegroundColor Yellow
Write-Host ""
pause
