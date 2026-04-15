$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " COMFYUI INSTALL + GENSTUDIO INTEGRATION "
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$Comfy = "$Root\ComfyUI"
$Models = "$Comfy\models"
$Custom = "$Comfy\custom_nodes"

# -------------------------
# CREAZIONE CARTELLE
# -------------------------
New-Item -ItemType Directory -Force -Path $Comfy | Out-Null
New-Item -ItemType Directory -Force -Path $Models | Out-Null
New-Item -ItemType Directory -Force -Path $Custom | Out-Null

# -------------------------
# CLONE COMFYUI
# -------------------------
Write-Host "Clonazione ComfyUI..."
git clone https://github.com/comfyanonymous/ComfyUI.git $Comfy

# -------------------------
# INSTALL PYTHON DEP
# -------------------------
Write-Host "Installazione requirements..."
cd $Comfy
python -m pip install --upgrade pip
pip install -r requirements.txt

# -------------------------
# INSTALL MANAGER
# -------------------------
Write-Host "Installazione ComfyUI-Manager..."
cd $Custom
git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# -------------------------
# INSTALL LTX NODE (VIDEO)
# -------------------------
Write-Host "Installazione LTX Video Nodes..."
git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git

# -------------------------
# CREA CARTELLE MODELLI
# -------------------------
New-Item -ItemType Directory -Force -Path "$Models\checkpoints" | Out-Null
New-Item -ItemType Directory -Force -Path "$Models\vae" | Out-Null
New-Item -ItemType Directory -Force -Path "$Models\loras" | Out-Null

# -------------------------
# LAUNCH SCRIPT
# -------------------------
$launch = @'
cd C:\SuiteV17\ComfyUI
python main.py --listen
'@

Set-Content "$Comfy\Launch-ComfyUI.bat" $launch -Encoding ASCII

# -------------------------
# DESKTOP ICON
# -------------------------
$desktop = [Environment]::GetFolderPath("Desktop")
Set-Content "$desktop\ComfyUI.bat" $launch -Encoding ASCII

# -------------------------
# PATCH GENSTUDIOAPP LINK
# -------------------------
$genIndex = "C:\SuiteV17\GenStudioApp\index.html"

if (Test-Path $genIndex) {
    (Get-Content $genIndex) -replace "</body>", @'
<button onclick="window.genStudioApp.openExternal('http://127.0.0.1:8188')">
Apri ComfyUI
</button>
</body>
'@ | Set-Content $genIndex -Encoding UTF8

    Write-Host "GenStudioApp aggiornata con link ComfyUI"
}

# -------------------------
# DONE
# -------------------------
Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " COMFYUI INSTALLATO " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Avvio manuale:"
Write-Host "C:\SuiteV17\ComfyUI\Launch-ComfyUI.bat"
Write-Host ""
Write-Host "Oppure da desktop:"
Write-Host "ComfyUI.bat"
Write-Host ""
Write-Host "URL:"
Write-Host "http://127.0.0.1:8188"