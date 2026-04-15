$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " AUDIOCRAFT GPU REAL INSTALL PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$AudioRoot = Join-Path $Root "AudioCraftEnv"
$Venv = Join-Path $AudioRoot ".venv"
$Scripts = Join-Path $AudioRoot "scripts"
$Output = Join-Path $AudioRoot "output"
$Logs = Join-Path $AudioRoot "logs"

foreach ($dir in @($AudioRoot, $Scripts, $Output, $Logs)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# -------------------------
# CHECK PYTHON 3.9
# -------------------------
Write-Host "Controllo Python 3.9..." -ForegroundColor Yellow
& py -3.9 --version 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Python 3.9 non trovato. Installa Python 3.9 e rilancia."
}

# -------------------------
# CREATE VENV
# -------------------------
if (!(Test-Path (Join-Path $Venv "Scripts\python.exe"))) {
    Write-Host "Creo venv AudioCraft con Python 3.9..." -ForegroundColor Yellow
    & py -3.9 -m venv $Venv
}

$PythonExe = Join-Path $Venv "Scripts\python.exe"
$PipExe = Join-Path $Venv "Scripts\pip.exe"

# -------------------------
# UPGRADE PIP TOOLS
# -------------------------
Write-Host "Aggiorno pip/setuptools/wheel..." -ForegroundColor Yellow
& $PythonExe -m pip install --upgrade pip setuptools wheel

# -------------------------
# INSTALL TORCH 2.1.0
# -------------------------
Write-Host "Installo PyTorch 2.1.0..." -ForegroundColor Yellow
try {
    & $PipExe uninstall -y torch torchvision torchaudio | Out-Host
} catch {}

# Prima provo CUDA recente; se fallisce, fallback CPU/non-index
$TorchInstalled = $false

$TorchCommands = @(
    'install torch==2.1.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118',
    'install torch==2.1.0 torchvision torchaudio'
)

foreach ($cmd in $TorchCommands) {
    if ($TorchInstalled) { break }
    try {
        Write-Host "pip $cmd" -ForegroundColor DarkCyan
        & $PipExe $cmd.Split(" ")
        if ($LASTEXITCODE -eq 0) {
            $TorchInstalled = $true
        }
    } catch {}
}

if (-not $TorchInstalled) {
    throw "Installazione torch 2.1.0 fallita."
}

# -------------------------
# INSTALL AUDIOCRAFT
# -------------------------
Write-Host "Installo AudioCraft..." -ForegroundColor Yellow
& $PipExe install -U audiocraft

# -------------------------
# FFMPEG CHECK
# -------------------------
$ffmpegFound = $null
try {
    $ffmpegFound = Get-Command ffmpeg -ErrorAction SilentlyContinue
} catch {}

if (-not $ffmpegFound) {
    Write-Host "ATTENZIONE: ffmpeg non trovato nel PATH. AudioCraft lo raccomanda." -ForegroundColor Yellow
}

# -------------------------
# TORCH PROBE
# -------------------------
$ProbePy = @'
import json
result = {
    "torch_installed": False,
    "cuda_available": False,
    "device_count": 0,
    "device_name": None,
    "torch_version": None,
    "cuda_version": None
}
try:
    import torch
    result["torch_installed"] = True
    result["torch_version"] = getattr(torch, "__version__", None)
    result["cuda_available"] = bool(torch.cuda.is_available())
    result["device_count"] = int(torch.cuda.device_count())
    result["cuda_version"] = getattr(torch.version, "cuda", None)
    if torch.cuda.is_available() and torch.cuda.device_count() > 0:
        result["device_name"] = torch.cuda.get_device_name(0)
except Exception as e:
    result["error"] = str(e)

print(json.dumps(result, indent=2))
'@

$ProbePath = Join-Path $Scripts "torch_probe.py"
Set-Content -Path $ProbePath -Value $ProbePy -Encoding UTF8

$ProbeOut = & $PythonExe $ProbePath
$ProbeFile = Join-Path $Logs ("torch_probe_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")
Set-Content -Path $ProbeFile -Value $ProbeOut -Encoding UTF8

# -------------------------
# MUSICGEN REAL GENERATOR
# -------------------------
$GenPy = @'
import argparse
from pathlib import Path
import torch
from audiocraft.models import MusicGen
from audiocraft.data.audio import audio_write

parser = argparse.ArgumentParser()
parser.add_argument("--prompt", required=True)
parser.add_argument("--duration", type=int, default=8)
parser.add_argument("--model", default="facebook/musicgen-small")
parser.add_argument("--output", required=True)
args = parser.parse_args()

device = "cuda" if torch.cuda.is_available() else "cpu"

model = MusicGen.get_pretrained(args.model, device=device)
model.set_generation_params(duration=args.duration)

wav = model.generate([args.prompt])
out = Path(args.output)
out.parent.mkdir(parents=True, exist_ok=True)

audio_write(
    out.with_suffix(""),
    wav[0].cpu(),
    model.sample_rate,
    strategy="loudness",
    loudness_compressor=True
)

print(str(out))
'@

$GenPath = Join-Path $Scripts "generate_music.py"
Set-Content -Path $GenPath -Value $GenPy -Encoding UTF8

# -------------------------
# PS WRAPPER
# -------------------------
$WrapperPs1 = @'
param(
    [string]$Prompt,
    [int]$Duration = 8,
    [string]$Model = "facebook/musicgen-small",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

$Root = "C:\SuiteV17\AudioCraftEnv"
$PythonExe = Join-Path $Root ".venv\Scripts\python.exe"
$ScriptPy = Join-Path $Root "scripts\generate_music.py"

if (-not $Prompt) {
    throw "Prompt mancante."
}

if (-not $OutputFile) {
    $OutputFile = Join-Path $Root ("output\music_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".wav")
}

$env:CUDA_VISIBLE_DEVICES = "0"
$env:FORCE_CUDA = "1"
$env:HF_HUB_DISABLE_TELEMETRY = "1"

& $PythonExe $ScriptPy --prompt $Prompt --duration $Duration --model $Model --output $OutputFile
'@

$WrapperPath = Join-Path $Scripts "audio_generate_real.ps1"
Set-Content -Path $WrapperPath -Value $WrapperPs1 -Encoding UTF8

# -------------------------
# DESKTOP LAUNCHER
# -------------------------
$Desktop = [Environment]::GetFolderPath("Desktop")
$DesktopBat = Join-Path $Desktop "AudioCraft MusicGen.bat"
$Bat = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\AudioCraftEnv\scripts\audio_generate_real.ps1"
'@
Set-Content -Path $DesktopBat -Value $Bat -Encoding ASCII

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " AUDIOCRAFT GPU PATCH COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Env:       C:\SuiteV17\AudioCraftEnv"
Write-Host "Wrapper:   C:\SuiteV17\AudioCraftEnv\scripts\audio_generate_real.ps1"
Write-Host "Probe:     $ProbeFile"
Write-Host ""
Write-Host "Test:"
Write-Host 'powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\AudioCraftEnv\scripts\audio_generate_real.ps1" -Prompt "dark cinematic soundtrack in GEN_e1799 style" -Duration 8 -Model "facebook/musicgen-small"'