$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " COMFYUI + GENSTUDIOAPP INTEGRATION PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$Comfy = Join-Path $Root "ComfyUI"
$CustomNodes = Join-Path $Comfy "custom_nodes"
$Models = Join-Path $Comfy "models"

$GenStudioApp = Join-Path $Root "GenStudioApp"
$GenIndex = Join-Path $GenStudioApp "index.html"
$GenPreload = Join-Path $GenStudioApp "preload.js"

$DesktopBat = Join-Path ([Environment]::GetFolderPath("Desktop")) "SuiteV17 ComfyUI.bat"

foreach ($dir in @(
    $Comfy,
    $CustomNodes,
    $Models,
    (Join-Path $Models "checkpoints"),
    (Join-Path $Models "vae"),
    (Join-Path $Models "loras"),
    (Join-Path $Models "controlnet"),
    (Join-Path $Models "upscale_models"),
    (Join-Path $Models "clip"),
    (Join-Path $Models "clip_vision"),
    (Join-Path $Models "diffusion_models")
)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
foreach ($f in @($GenIndex, $GenPreload)) {
    if (Test-Path $f) {
        Copy-Item $f "$f.bak_$ts" -Force
    }
}

# -------------------------
# PREREQ CHECK
# -------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git non trovato nel PATH. Installa Git for Windows e rilancia la patch."
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "python non trovato nel PATH. Installa Python 3.10+ e rilancia la patch."
}

# -------------------------
# CLONE / UPDATE COMFYUI
# -------------------------
if (!(Test-Path (Join-Path $Comfy ".git"))) {
    Write-Host "Clonazione ComfyUI..." -ForegroundColor Yellow
    git clone https://github.com/comfy-org/ComfyUI.git $Comfy
} else {
    Write-Host "ComfyUI già presente, aggiorno..." -ForegroundColor Yellow
    git -C $Comfy pull
}

# -------------------------
# VENV
# -------------------------
$Venv = Join-Path $Comfy ".venv"
$PythonExe = Join-Path $Venv "Scripts\python.exe"
$PipExe = Join-Path $Venv "Scripts\pip.exe"

if (!(Test-Path $PythonExe)) {
    Write-Host "Creo virtualenv ComfyUI..." -ForegroundColor Yellow
    python -m venv $Venv
}

Write-Host "Aggiorno pip..." -ForegroundColor Yellow
& $PythonExe -m pip install --upgrade pip

Write-Host "Installo requirements ComfyUI..." -ForegroundColor Yellow
& $PipExe install -r (Join-Path $Comfy "requirements.txt")

# -------------------------
# MANAGER
# -------------------------
$ManagerPath = Join-Path $CustomNodes "ComfyUI-Manager"
if (!(Test-Path (Join-Path $ManagerPath ".git"))) {
    Write-Host "Clonazione ComfyUI-Manager..." -ForegroundColor Yellow
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git $ManagerPath
} else {
    Write-Host "ComfyUI-Manager già presente, aggiorno..." -ForegroundColor Yellow
    git -C $ManagerPath pull
}

# -------------------------
# LTX NODE
# -------------------------
$LTXNodePath = Join-Path $CustomNodes "ComfyUI-LTXVideo"
if (!(Test-Path (Join-Path $LTXNodePath ".git"))) {
    Write-Host "Clonazione ComfyUI-LTXVideo..." -ForegroundColor Yellow
    git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git $LTXNodePath
} else {
    Write-Host "ComfyUI-LTXVideo già presente, aggiorno..." -ForegroundColor Yellow
    git -C $LTXNodePath pull
}

if (Test-Path (Join-Path $LTXNodePath "requirements.txt")) {
    Write-Host "Installo requirements ComfyUI-LTXVideo..." -ForegroundColor Yellow
    & $PipExe install -r (Join-Path $LTXNodePath "requirements.txt")
}

# -------------------------
# OPTIONAL TORCH CHECK
# -------------------------
Write-Host "Controllo Torch/CUDA nel venv ComfyUI..." -ForegroundColor Yellow
$torchCheck = @'
import json
result = {"torch_installed": False, "cuda_available": False, "device_name": None}
try:
    import torch
    result["torch_installed"] = True
    result["cuda_available"] = bool(torch.cuda.is_available())
    if torch.cuda.is_available():
        result["device_name"] = torch.cuda.get_device_name(0)
except Exception as e:
    result["error"] = str(e)
print(json.dumps(result))
'@
$TorchResult = & $PythonExe -c $torchCheck
Write-Host "Torch status: $TorchResult" -ForegroundColor DarkCyan

# -------------------------
# LAUNCHERS
# -------------------------
$LaunchPs1 = @'
$ErrorActionPreference = "Stop"
Set-Location "C:\SuiteV17\ComfyUI"

if (!(Test-Path ".\.venv\Scripts\python.exe")) {
    throw "Virtualenv ComfyUI non trovato."
}

$env:CUDA_VISIBLE_DEVICES = "0"
$env:FORCE_CUDA = "1"
$env:HF_HUB_DISABLE_TELEMETRY = "1"

& ".\.venv\Scripts\python.exe" ".\main.py" --listen 127.0.0.1 --port 8188
'@

$LaunchBat = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1"
'@

Set-Content (Join-Path $Comfy "Launch-ComfyUI.ps1") $LaunchPs1 -Encoding UTF8
Set-Content (Join-Path $Comfy "Launch-ComfyUI.bat") $LaunchBat -Encoding ASCII
Set-Content $DesktopBat $LaunchBat -Encoding ASCII

# -------------------------
# MODEL PLACEHOLDER FILE
# -------------------------
$ReadmeModels = @'
COMFYUI MODEL FOLDERS

Metti qui i modelli scaricati:

- checkpoints  -> C:\SuiteV17\ComfyUI\models\checkpoints
- vae          -> C:\SuiteV17\ComfyUI\models\vae
- loras        -> C:\SuiteV17\ComfyUI\models\loras
- controlnet   -> C:\SuiteV17\ComfyUI\models\controlnet
- upscale      -> C:\SuiteV17\ComfyUI\models\upscale_models
- clip         -> C:\SuiteV17\ComfyUI\models\clip
- clip_vision  -> C:\SuiteV17\ComfyUI\models\clip_vision
- diffusion    -> C:\SuiteV17\ComfyUI\models\diffusion_models

Suggerimento operativo:
- 1080p default
- 1440p qualità alta
- 4K preset avanzato/finale
'@
Set-Content (Join-Path $Comfy "MODELS_README.txt") $ReadmeModels -Encoding UTF8

# -------------------------
# PATCH GENSTUDIOAPP PRELOAD
# -------------------------
if (Test-Path $GenPreload) {
    $preloadText = Get-Content $GenPreload -Raw
    if ($preloadText -notmatch "startComfyUI") {
        $preloadText = $preloadText -replace 'contextBridge\.exposeInMainWorld\("genStudioApp", \{', @'
contextBridge.exposeInMainWorld("genStudioApp", {
  startComfyUI: () => startProcess(".\\main.py --listen 127.0.0.1 --port 8188", "C:\\SuiteV17\\ComfyUI"),
'@
        $preloadText = $preloadText -replace "const cmd = `Start-Process node -ArgumentList '\$\{script\}' -WorkingDirectory '\$\{cwd\}'`;", @'
    const cmd = cwd.includes("ComfyUI")
      ? `Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1""'`
      : `Start-Process node -ArgumentList '${script}' -WorkingDirectory '${cwd}'`;
'@
        Set-Content $GenPreload $preloadText -Encoding UTF8
    }
}

# -------------------------
# PATCH GENSTUDIOAPP INDEX
# -------------------------
if (Test-Path $GenIndex) {
    $html = Get-Content $GenIndex -Raw

    if ($html -notmatch "startComfyUI") {
        $html = $html -replace '<button id="startGenStudio">Avvia GenStudio</button>', @'
<button id="startGenStudio">Avvia GenStudio</button>
<button id="startComfyUI">Avvia ComfyUI</button>
<button id="openComfyUI">Apri ComfyUI</button>
'@
    }

    if ($html -notmatch 'document\.getElementById\("startComfyUI"\)') {
        $html = $html -replace 'document\.getElementById\("startGenStudio"\)\.onclick = async \(\)=> outputBox\.textContent = JSON\.stringify\(await window\.genStudioApp\.startGenStudio\(\), null, 2\);', @'
document.getElementById("startGenStudio").onclick = async ()=> outputBox.textContent = JSON.stringify(await window.genStudioApp.startGenStudio(), null, 2);
document.getElementById("startComfyUI").onclick = async ()=> outputBox.textContent = JSON.stringify(await window.genStudioApp.startComfyUI(), null, 2);
document.getElementById("openComfyUI").onclick = ()=> window.genStudioApp.openPath("C:\\SuiteV17\\ComfyUI");
'@
    }

    Set-Content $GenIndex $html -Encoding UTF8
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " PATCH COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "ComfyUI: C:\SuiteV17\ComfyUI"
Write-Host "Launcher desktop: $DesktopBat"
Write-Host "UI locale attesa: http://127.0.0.1:8188"
Write-Host ""
Write-Host "Note:"
Write-Host " - I modelli non sono inclusi: vanno aggiunti sotto C:\SuiteV17\ComfyUI\models"
Write-Host " - Se Torch nel venv non vede CUDA, installa PyTorch CUDA nel venv ComfyUI con il comando ufficiale PyTorch"
Write-Host " - GenStudioApp ora ha i pulsanti per ComfyUI"