$ErrorActionPreference = "Stop"

$LaunchPath = "C:\SuiteV17\ComfyUI\Launch-ComfyUI.ps1"

$Content = @'
$ErrorActionPreference = "Stop"

$Base1 = "C:\SuiteV17\ComfyUI"
$Base2 = "C:\SuiteV17\ComfyUI\ComfyUI"

if (Test-Path "$Base1\main.py") {
    $ComfyRoot = $Base1
}
elseif (Test-Path "$Base2\main.py") {
    $ComfyRoot = $Base2
}
else {
    throw "main.py non trovato né in $Base1 né in $Base2"
}

Set-Location $ComfyRoot

$Python1 = Join-Path $Base1 ".venv\Scripts\python.exe"
$Python2 = Join-Path $Base2 ".venv\Scripts\python.exe"

if (Test-Path $Python1) {
    $PythonExe = $Python1
}
elseif (Test-Path $Python2) {
    $PythonExe = $Python2
}
else {
    throw "Python del venv non trovato."
}

$env:CUDA_VISIBLE_DEVICES = "0"
$env:FORCE_CUDA = "1"
$env:HF_HUB_DISABLE_TELEMETRY = "1"

& $PythonExe ".\main.py" --listen 127.0.0.1 --port 8188
'@

Set-Content -Path $LaunchPath -Value $Content -Encoding UTF8

Write-Host "Launch-ComfyUI.ps1 corretto." -ForegroundColor Green