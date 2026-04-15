$ErrorActionPreference = "Stop"

$secretPath = Join-Path $env:USERPROFILE ".suitev17\groq_api_key.secure"

if (Test-Path $secretPath) {
    Remove-Item $secretPath -Force
    Write-Host "Chiave locale eliminata: $secretPath" -ForegroundColor Yellow
} else {
    Write-Host "Nessuna chiave locale trovata." -ForegroundColor DarkYellow
}

if (Test-Path Env:GROQ_API_KEY) {
    Remove-Item Env:GROQ_API_KEY -ErrorAction SilentlyContinue
    Write-Host "Variabile di sessione GROQ_API_KEY rimossa." -ForegroundColor Yellow
} else {
    Write-Host "Nessuna GROQ_API_KEY nella sessione corrente." -ForegroundColor DarkYellow
}

Write-Host "Reset completato." -ForegroundColor Green
