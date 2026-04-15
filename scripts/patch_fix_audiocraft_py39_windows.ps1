$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " AUDIOCRAFT FIX WINDOWS // PY39 + AV FIRST "
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

function Write-Log {
    param([string]$Message)
    $logFile = Join-Path $Logs "install_fix.log"
    $line = "[{0}] {1}" -f (Get-Date -Format "s"), $Message
    Add-Content -Path $logFile -Value $line
    Write-Host $Message
}

Write-Log "Controllo Python 3.9..."
& py -3.9 --version 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Python 3.9 non trovato. Installa Python 3.9 e rilancia."
}

Write-Log "Controllo ffmpeg..."
$ffmpegCmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegCmd) {
    Write-Host ""
    Write-Host "ERRORE: ffmpeg non trovato nel PATH." -ForegroundColor Red
    Write-Host "Installa ffmpeg e riapri PowerShell, poi rilancia la patch." -ForegroundColor Yellow
    throw "ffmpeg mancante"
}

Write-Log "Controllo Microsoft C++ Build Tools..."
$clCmd = Get-Command cl.exe -ErrorAction SilentlyContinue
if (-not $clCmd) {
    Write-Host ""
    Write-Host "ERRORE: cl.exe non trovato." -ForegroundColor Red
    Write-Host "Installa Microsoft C++ Build Tools e riapri PowerShell, poi rilancia la patch." -ForegroundColor Yellow
    throw "Microsoft C++ Build Tools mancanti"
}

if (Test-Path $Venv) {
    Write-Log "Rimuovo venv precedente..."
    Remove-Item $Venv -Recurse -Force
}

Write-Log "Creo nuovo venv con Python 3.9..."
& py -3.9 -m venv $Venv

$PythonExe = Join-Path $Venv "Scripts\python.exe"
$PipExe = Join-Path $Venv "Scripts\pip.exe"

Write-Log "Aggiorno pip/setuptools/wheel..."
& $PythonExe -m pip install --upgrade pip setuptools wheel

Write-Log "Pulisco eventuali installazioni torch precedenti..."
try {
    & $PipExe uninstall -y torch torchvision torchaudio av audiocraft | Out-Host
} catch {}

Write-Log "Installo PyTorch 2.1.0 CUDA 11.8..."
& $PipExe install torch==2.1.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

Write-Log "Installo AV prima di AudioCraft..."
& $PipExe install av

Write-Log "Installo AudioCraft..."
& $PipExe install -U audiocraft

$ProbePy = @'
import json
result = {
    "torch_installed": False,
    "cuda_available": False,
    "device_count": 0,
    "device_name": None,
    "torch_version": None,
    "cuda_version": None,
    "audiocraft_import": False,
    "ffmpeg": None,
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
    result["torch_error"] = str(e)

try:
    import audiocraft
    result["audiocraft_import"] = True
except Exception as e:
    result["audiocraft_error"] = str(e)

print(json.dumps(result, indent=2))
'@

$ProbePath = Join-Path $Scripts "probe_env.py"
Set-Content -Path $ProbePath -Value $ProbePy -Encoding UTF8

Write-Log "Eseguo probe ambiente..."
$probeOut = & $PythonExe $ProbePath
$ProbeFile = Join-Path $Logs ("probe_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")
Set-Content -Path $ProbeFile -Value $probeOut -Encoding UTF8
Write-Host $probeOut

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

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " AUDIOCRAFT FIX COMPLETATO " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Probe: $ProbeFile"
Write-Host ""
Write-Host "Test:"
Write-Host 'powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\AudioCraftEnv\scripts\audio_generate_real.ps1" -Prompt "dark cinematic soundtrack in GEN_e1799 style" -Duration 8 -Model "facebook/musicgen-small"'