$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " COMFYUI // MODELS + TORCH CUDA PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$Comfy = Join-Path $Root "ComfyUI"
$Venv = Join-Path $Comfy ".venv"
$PythonExe = Join-Path $Venv "Scripts\python.exe"
$PipExe = Join-Path $Venv "Scripts\pip.exe"

$Models = Join-Path $Comfy "models"
$Checkpoints = Join-Path $Models "checkpoints"
$Vae = Join-Path $Models "vae"
$Logs = Join-Path $Comfy "logs"
$Tools = Join-Path $Comfy "tools"

foreach ($dir in @($Models,$Checkpoints,$Vae,$Logs,$Tools)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

if (!(Test-Path $PythonExe)) {
    throw "Virtualenv ComfyUI non trovato in $Venv. Prima installa/inizializza ComfyUI."
}

function Write-Log {
    param([string]$Message)
    $logFile = Join-Path $Logs "patch_models_torch_cuda.log"
    $line = "[{0}] {1}" -f (Get-Date -Format "s"), $Message
    Add-Content -Path $logFile -Value $line
    Write-Host $Message
}

function Download-File {
    param(
        [string]$Url,
        [string]$Destination
    )

    if (Test-Path $Destination) {
        Write-Log "Già presente: $Destination"
        return
    }

    Write-Log "Download: $Url"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
        Write-Log "Scaricato: $Destination"
    } catch {
        Write-Log "Errore download: $($_.Exception.Message)"
        throw
    }
}

Write-Log "Upgrade pip..."
& $PythonExe -m pip install --upgrade pip

Write-Log "Pulizia eventuali torch precedenti..."
try {
    & $PipExe uninstall -y torch torchvision torchaudio | Out-Host
} catch {}

$TorchInstalled = $false
$TorchTries = @(
    "https://download.pytorch.org/whl/cu128",
    "https://download.pytorch.org/whl/cu126",
    "https://download.pytorch.org/whl/cu118"
)

foreach ($idx in $TorchTries) {
    if ($TorchInstalled) { break }
    try {
        Write-Log "Installo torch da index: $idx"
        & $PipExe install torch torchvision torchaudio --index-url $idx
        if ($LASTEXITCODE -eq 0) {
            $TorchInstalled = $true
            Write-Log "Torch installato con successo da $idx"
        }
    } catch {
        Write-Log "Tentativo fallito su $idx : $($_.Exception.Message)"
    }
}

if (-not $TorchInstalled) {
    throw "Impossibile installare torch CUDA nel venv ComfyUI."
}

$TorchProbe = @'
import json
result = {"torch_installed": False, "cuda_available": False, "device_count": 0, "device_name": None, "torch_version": None, "cuda_version": None}
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

$TorchProbeFile = Join-Path $Tools "torch_probe.py"
Set-Content -Path $TorchProbeFile -Value $TorchProbe -Encoding UTF8

Write-Log "Eseguo probe torch/cuda..."
$probeOut = & $PythonExe $TorchProbeFile
$ProbeJsonFile = Join-Path $Logs ("torch_probe_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")
Set-Content -Path $ProbeJsonFile -Value $probeOut -Encoding UTF8
Write-Log "Probe salvata in: $ProbeJsonFile"
Write-Host $probeOut

# -------------------------
# MODEL SOURCES
# -------------------------
# Base consigliato per partire subito con ComfyUI
$Sd15Url = "https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors"
$Sd15Dest = Join-Path $Checkpoints "v1-5-pruned-emaonly-fp16.safetensors"

# Opzionale: SDXL Turbo (più pesante)
$SdxlTurboUrl = "https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors"
$SdxlTurboDest = Join-Path $Checkpoints "sd_xl_turbo_1.0_fp16.safetensors"

# Opzionale: VAE SDXL Turbo
$SdxlTurboVaeUrl = "https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/vae/diffusion_pytorch_model.safetensors"
$SdxlTurboVaeDest = Join-Path $Vae "sdxl_turbo_vae.safetensors"

# Impostazioni download
$DownloadSd15 = $true
$DownloadSdxlTurbo = $false
$DownloadSdxlTurboVae = $false

if ($DownloadSd15) {
    Download-File -Url $Sd15Url -Destination $Sd15Dest
}

if ($DownloadSdxlTurbo) {
    Download-File -Url $SdxlTurboUrl -Destination $SdxlTurboDest
}

if ($DownloadSdxlTurboVae) {
    Download-File -Url $SdxlTurboVaeUrl -Destination $SdxlTurboVaeDest
}

$ModelsManifest = [pscustomobject]@{
    generatedAt = (Get-Date).ToString("s")
    comfyRoot = $Comfy
    checkpoints = @(
        [pscustomobject]@{
            name = "v1-5-pruned-emaonly-fp16.safetensors"
            path = $Sd15Dest
            downloaded = (Test-Path $Sd15Dest)
            purpose = "base model per partire subito in ComfyUI"
        },
        [pscustomobject]@{
            name = "sd_xl_turbo_1.0_fp16.safetensors"
            path = $SdxlTurboDest
            downloaded = (Test-Path $SdxlTurboDest)
            purpose = "modello SDXL Turbo opzionale"
        }
    )
    vae = @(
        [pscustomobject]@{
            name = "sdxl_turbo_vae.safetensors"
            path = $SdxlTurboVaeDest
            downloaded = (Test-Path $SdxlTurboVaeDest)
            purpose = "VAE opzionale per SDXL Turbo"
        }
    )
    notes = @(
        "ComfyUI non include i modelli base",
        "Metti i checkpoint in models\\checkpoints",
        "Metti i VAE in models\\vae",
        "Per workflow stabili usa 1080p default",
        "Usa 4K solo come preset avanzato/finale"
    )
}
$ManifestPath = Join-Path $Comfy "MODELS_MANIFEST.json"
$ModelsManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $ManifestPath -Encoding UTF8

Write-Log "Manifest modelli salvato in: $ManifestPath"

$Readme = @"
COMFYUI MODELS READY

Installato / preparato:
- Torch CUDA nel venv ComfyUI
- Probe GPU/Torch
- Checkpoint base SD1.5 (se download attivo)
- SDXL Turbo opzionale (se abilitato)

Cartelle:
- Checkpoints: $Checkpoints
- VAE:         $Vae

Per avviare ComfyUI:
C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1

Per vedere il probe:
$ProbeJsonFile
"@
Set-Content -Path (Join-Path $Comfy "README_MODELS_SETUP.txt") -Value $Readme -Encoding UTF8

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " PATCH COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Torch probe: $ProbeJsonFile"
Write-Host "Manifest:    $ManifestPath"
Write-Host ""
Write-Host "Avvio ComfyUI:"
Write-Host 'powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1"'