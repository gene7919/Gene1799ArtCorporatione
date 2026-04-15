$ErrorActionPreference = "Continue"

$BasePath = "C:\SuiteV17"
Set-Location $BasePath

if (!(Test-Path ".\node_modules")) {
    npm install
}

if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "ollama serve"
}
elseif (Test-Path "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe") {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "& '$env:LOCALAPPDATA\Programs\Ollama\ollama.exe' serve"
}
else {
    Write-Host "Ollama non trovato: avvialo manualmente." -ForegroundColor Yellow
}

Start-Sleep -Seconds 4
node .\server.js
