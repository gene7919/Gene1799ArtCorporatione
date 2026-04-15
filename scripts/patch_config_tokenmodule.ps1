$ErrorActionPreference = "Stop"

$ConfigPath = "C:\SuiteV17\TokenModule\config.json"

if (!(Test-Path $ConfigPath)) {
    throw "config.json non trovato. Esegui prima le patch precedenti."
}

Write-Host "===============================" -ForegroundColor Cyan
Write-Host " CONFIG GENE1799 TOKEN MODULE " -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# INPUT UTENTE
$webhook = Read-Host "Inserisci WEBHOOK (Make/n8n) oppure lascia vuoto"
$botToken = Read-Host "Inserisci BOT TOKEN Telegram"
$chatId = Read-Host "Inserisci CHAT ID Telegram"

# LEGGE CONFIG ATTUALE
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# AGGIORNA
$config.social.webhook = $webhook
$config.social.enabled = $true

$config.telegram.botToken = $botToken
$config.telegram.chatId = $chatId
$config.telegram.enabled = $true

# SALVA
$config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8

Write-Host "✔ Config aggiornata" -ForegroundColor Green

# RIAVVIO PM2
if (Get-Command pm2 -ErrorAction SilentlyContinue) {
    Write-Host "Riavvio processi..." -ForegroundColor Yellow

    pm2 restart GENE1799-TOKEN | Out-Null
    pm2 restart GENE1799-DASH | Out-Null

    Write-Host "✔ PM2 riavviato" -ForegroundColor Green
} else {
    Write-Host "⚠ PM2 non trovato" -ForegroundColor Red
}

# TEST TELEGRAM
if ($botToken -and $chatId) {
    try {
        $url = "https://api.telegram.org/bot$botToken/sendMessage"

        Invoke-RestMethod -Uri $url `
            -Method Post `
            -ContentType "application/json" `
            -Body (@{
                chat_id = $chatId
                text = "🔥 GENE1799 TOKEN MODULE ATTIVO"
            } | ConvertTo-Json)

        Write-Host "✔ Test Telegram OK" -ForegroundColor Green
    } catch {
        Write-Host "❌ Errore Telegram" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "===============================" -ForegroundColor Cyan
Write-Host " CONFIG COMPLETATA " -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Cyan