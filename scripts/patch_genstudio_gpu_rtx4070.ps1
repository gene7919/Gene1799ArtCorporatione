$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SUITE V17 // GPU ENABLE RTX 4070 SUPER " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$GenStudio = Join-Path $Root "GenStudio"
$Skills = Join-Path $GenStudio "skills"
$Logs = Join-Path $GenStudio "logs"
$Tools = Join-Path $GenStudio "tools"
$ConfigPath = Join-Path $GenStudio "config.json"

foreach ($dir in @($GenStudio, $Skills, $Logs, $Tools)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$ts = Get-Date -Format "yyyyMMdd_HHmmss"

$GpuConfigPath = Join-Path $GenStudio "gpu_config.json"
$GpuDiagPs1 = Join-Path $Tools "gpu_diagnostics.ps1"
$GpuDiagPy = Join-Path $Tools "gpu_probe.py"
$AudioGpuWrapper = Join-Path $Skills "audio_generate_gpu.ps1"
$VideoGpuWrapper = Join-Path $Skills "video_generate_gpu.ps1"
$SetGpuEnv = Join-Path $Tools "set_gpu_env.ps1"

foreach ($f in @($GpuConfigPath, $GpuDiagPs1, $GpuDiagPy, $AudioGpuWrapper, $VideoGpuWrapper, $SetGpuEnv)) {
    if (Test-Path $f) {
        Copy-Item $f "$f.bak_$ts" -Force
    }
}

$gpuConfig = @'
{
  "gpu": {
    "preferred": true,
    "deviceType": "cuda",
    "vendor": "nvidia",
    "modelHint": "GeForce RTX 4070 SUPER",
    "torchDevice": "cuda",
    "ffmpegHwAccel": "cuda",
    "ffmpegEncoder": "h264_nvenc",
    "videoEncoderFallback": "libx264",
    "audioUseCudaIfAvailable": true,
    "videoUseCudaIfAvailable": true,
    "pythonExecutable": "python",
    "venvPython": "C:\\SuiteV17\\venv\\Scripts\\python.exe",
    "notes": [
      "Richiede driver NVIDIA installati correttamente",
      "Torch deve essere installato con supporto CUDA nel relativo ambiente Python",
      "MusicGen/AudioCraft e LTX-Video vanno collegati separatamente"
    ]
  }
}
'@

$setGpuEnvContent = @'
$env:CUDA_VISIBLE_DEVICES = "0"
$env:PYTORCH_ENABLE_MPS_FALLBACK = "0"
$env:HF_HUB_DISABLE_TELEMETRY = "1"
$env:TORCH_CUDA_ARCH_LIST = "8.9"
$env:FORCE_CUDA = "1"
$env:NVIDIA_VISIBLE_DEVICES = "all"
$env:TF_CPP_MIN_LOG_LEVEL = "2"

Write-Host "GPU environment variables impostate per la sessione corrente." -ForegroundColor Green
'@

$gpuDiagPyContent = @'
import json
import shutil
import subprocess
import sys

result = {
    "python": sys.executable,
    "torch": {
        "installed": False,
        "cuda_available": False,
        "device_count": 0,
        "device_name": None,
        "torch_version": None,
        "cuda_version": None,
    },
    "ffmpeg": {
        "found": shutil.which("ffmpeg") is not None,
        "nvenc": False,
        "cuda_hwaccel": False
    },
    "nvidia_smi": {
        "found": shutil.which("nvidia-smi") is not None,
        "output": None
    }
}

try:
    import torch
    result["torch"]["installed"] = True
    result["torch"]["torch_version"] = getattr(torch, "__version__", None)
    result["torch"]["cuda_available"] = torch.cuda.is_available()
    result["torch"]["device_count"] = torch.cuda.device_count()
    result["torch"]["cuda_version"] = getattr(torch.version, "cuda", None)
    if torch.cuda.is_available() and torch.cuda.device_count() > 0:
        result["torch"]["device_name"] = torch.cuda.get_device_name(0)
except Exception as e:
    result["torch"]["error"] = str(e)

try:
    if result["ffmpeg"]["found"]:
        enc = subprocess.run(["ffmpeg", "-hide_banner", "-encoders"], capture_output=True, text=True)
        txt = (enc.stdout or "") + "\n" + (enc.stderr or "")
        result["ffmpeg"]["nvenc"] = "h264_nvenc" in txt or "hevc_nvenc" in txt

        hw = subprocess.run(["ffmpeg", "-hide_banner", "-hwaccels"], capture_output=True, text=True)
        htxt = (hw.stdout or "") + "\n" + (hw.stderr or "")
        result["ffmpeg"]["cuda_hwaccel"] = "cuda" in htxt.lower()
except Exception as e:
    result["ffmpeg"]["error"] = str(e)

try:
    if result["nvidia_smi"]["found"]:
        smi = subprocess.run(["nvidia-smi"], capture_output=True, text=True)
        result["nvidia_smi"]["output"] = (smi.stdout or smi.stderr)
except Exception as e:
    result["nvidia_smi"]["error"] = str(e)

print(json.dumps(result, indent=2))
'@

$gpuDiagPs1Content = @'
$ErrorActionPreference = "Continue"

$Root = "C:\SuiteV17\GenStudio"
$Tools = Join-Path $Root "tools"
$Logs = Join-Path $Root "logs"
$PyProbe = Join-Path $Tools "gpu_probe.py"
$OutFile = Join-Path $Logs ("gpu_diag_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")

function Get-PythonCandidates {
    $candidates = @(
        "C:\SuiteV17\venv\Scripts\python.exe",
        "C:\Users\marco\Desktop\SuiteV17\venv\Scripts\python.exe",
        "python"
    )
    return $candidates
}

$pythonExe = $null
foreach ($candidate in Get-PythonCandidates) {
    try {
        if ($candidate -eq "python") {
            $null = & python --version 2>$null
            if ($LASTEXITCODE -eq 0) { $pythonExe = "python"; break }
        } elseif (Test-Path $candidate) {
            $pythonExe = $candidate
            break
        }
    } catch {}
}

if (-not $pythonExe) {
    throw "Nessun Python valido trovato."
}

Write-Host "Uso Python: $pythonExe" -ForegroundColor Yellow

$json = & $pythonExe $PyProbe
$json | Set-Content $OutFile -Encoding UTF8

Write-Host "Diagnostica GPU salvata in: $OutFile" -ForegroundColor Green
Write-Host ""
Write-Host $json
'@

$audioGpuWrapperContent = @'
param(
    [string]$Prompt,
    [int]$Duration = 8,
    [string]$Style = "cinematic",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

if (-not $Prompt) {
    throw "Prompt audio mancante."
}

if (-not $OutputFile) {
    $OutputFile = "C:\SuiteV17\GenStudio\output\audio\audio_gpu_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json"
}

$env:CUDA_VISIBLE_DEVICES = "0"
$env:FORCE_CUDA = "1"
$env:TORCH_CUDA_ARCH_LIST = "8.9"

$result = @{
    ok = $true
    engine = "audio_generate_gpu"
    gpuPreferred = $true
    prompt = $Prompt
    duration = $Duration
    style = $Style
    outputTarget = $OutputFile
    note = "Wrapper GPU pronto. Collegare qui MusicGen/AudioCraft con torch CUDA."
    createdAt = (Get-Date).ToString("s")
}

$result | ConvertTo-Json -Depth 20 | Set-Content $OutputFile -Encoding UTF8
Write-Host "Audio GPU wrapper prepared -> $OutputFile" -ForegroundColor Green
'@

$videoGpuWrapperContent = @'
param(
    [string]$Prompt,
    [int]$Duration = 4,
    [int]$Fps = 24,
    [string]$Resolution = "768x432",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

if (-not $Prompt) {
    throw "Prompt video mancante."
}

if (-not $OutputFile) {
    $OutputFile = "C:\SuiteV17\GenStudio\output\video\video_gpu_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json"
}

$env:CUDA_VISIBLE_DEVICES = "0"
$env:FORCE_CUDA = "1"
$env:TORCH_CUDA_ARCH_LIST = "8.9"

$result = @{
    ok = $true
    engine = "video_generate_gpu"
    gpuPreferred = $true
    prompt = $Prompt
    duration = $Duration
    fps = $Fps
    resolution = $Resolution
    outputTarget = $OutputFile
    ffmpegEncoder = "h264_nvenc"
    note = "Wrapper GPU pronto. Collegare qui LTX-Video e/o ffmpeg NVENC."
    createdAt = (Get-Date).ToString("s")
}

$result | ConvertTo-Json -Depth 20 | Set-Content $OutputFile -Encoding UTF8
Write-Host "Video GPU wrapper prepared -> $OutputFile" -ForegroundColor Green
'@

Set-Content -Path $GpuConfigPath -Value $gpuConfig -Encoding UTF8
Set-Content -Path $SetGpuEnv -Value $setGpuEnvContent -Encoding UTF8
Set-Content -Path $GpuDiagPy -Value $gpuDiagPyContent -Encoding UTF8
Set-Content -Path $GpuDiagPs1 -Value $gpuDiagPs1Content -Encoding UTF8
Set-Content -Path $AudioGpuWrapper -Value $audioGpuWrapperContent -Encoding UTF8
Set-Content -Path $VideoGpuWrapper -Value $videoGpuWrapperContent -Encoding UTF8

if (Test-Path $ConfigPath) {
    $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json

    if (-not ($cfg.PSObject.Properties.Name -contains "gpu")) {
        $cfg | Add-Member -MemberType NoteProperty -Name gpu -Value ([pscustomobject]@{
            enabled = $true
            vendor = "nvidia"
            modelHint = "GeForce RTX 4070 SUPER"
            deviceType = "cuda"
            ffmpegEncoder = "h264_nvenc"
            ffmpegHwAccel = "cuda"
        })
    } else {
        $cfg.gpu.enabled = $true
        $cfg.gpu.vendor = "nvidia"
        $cfg.gpu.modelHint = "GeForce RTX 4070 SUPER"
        $cfg.gpu.deviceType = "cuda"
        $cfg.gpu.ffmpegEncoder = "h264_nvenc"
        $cfg.gpu.ffmpegHwAccel = "cuda"
    }

    if ($cfg.PSObject.Properties.Name -contains "audio") {
        if (-not ($cfg.audio.PSObject.Properties.Name -contains "gpuScript")) {
            $cfg.audio | Add-Member -MemberType NoteProperty -Name gpuScript -Value "C:\SuiteV17\GenStudio\skills\audio_generate_gpu.ps1"
        } else {
            $cfg.audio.gpuScript = "C:\SuiteV17\GenStudio\skills\audio_generate_gpu.ps1"
        }
        if (-not ($cfg.audio.PSObject.Properties.Name -contains "preferGpu")) {
            $cfg.audio | Add-Member -MemberType NoteProperty -Name preferGpu -Value $true
        } else {
            $cfg.audio.preferGpu = $true
        }
    }

    if ($cfg.PSObject.Properties.Name -contains "video") {
        if (-not ($cfg.video.PSObject.Properties.Name -contains "gpuScript")) {
            $cfg.video | Add-Member -MemberType NoteProperty -Name gpuScript -Value "C:\SuiteV17\GenStudio\skills\video_generate_gpu.ps1"
        } else {
            $cfg.video.gpuScript = "C:\SuiteV17\GenStudio\skills\video_generate_gpu.ps1"
        }
        if (-not ($cfg.video.PSObject.Properties.Name -contains "preferGpu")) {
            $cfg.video | Add-Member -MemberType NoteProperty -Name preferGpu -Value $true
        } else {
            $cfg.video.preferGpu = $true
        }
    }

    $cfg | ConvertTo-Json -Depth 30 | Set-Content $ConfigPath -Encoding UTF8
    Write-Host "config.json aggiornato con preferenze GPU." -ForegroundColor Green
} else {
    Write-Host "config.json non trovato, creati solo file GPU separati." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " PATCH GPU COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Creati:"
Write-Host " - $GpuConfigPath"
Write-Host " - $SetGpuEnv"
Write-Host " - $GpuDiagPs1"
Write-Host " - $GpuDiagPy"
Write-Host " - $AudioGpuWrapper"
Write-Host " - $VideoGpuWrapper"
Write-Host ""
Write-Host "Test GPU:"
Write-Host 'powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\GenStudio\tools\gpu_diagnostics.ps1"'
Write-Host ""
Write-Host "Test wrapper audio GPU:"
Write-Host 'powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\GenStudio\skills\audio_generate_gpu.ps1" -Prompt "dark cinematic soundtrack" -Duration 8 -Style "cinematic"'
Write-Host ""
Write-Host "Test wrapper video GPU:"
Write-Host 'powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\GenStudio\skills\video_generate_gpu.ps1" -Prompt "dark futuristic city" -Duration 4 -Fps 24 -Resolution "768x432"'