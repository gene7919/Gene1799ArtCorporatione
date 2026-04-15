# ================================
# launch_openclaw.ps1
# SuiteV17 + Ollama Nemotron-3-Super
# ================================

$SuitePath = "C:\SuiteV17"

Write-Host "🚀 Avvio SuiteV17 con Nemotron-3-Super..." -ForegroundColor Cyan

# 1️⃣ Controlla Ollama CLI
if (!(Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "📥 Ollama non trovato. Scarico e installo..."
    Invoke-WebRequest -Uri "https://ollama.com/downloads/ollama-win-latest.exe" -OutFile "$env:TEMP\ollama_installer.exe"
    Start-Process "$env:TEMP\ollama_installer.exe" -Wait
    Write-Host "✅ Ollama CLI installato"
} else {
    Write-Host "✅ Ollama CLI già presente"
}

# 2️⃣ Avvia il server Ollama se non già attivo
Write-Host "🖥️ Controllo server Ollama..."
$ServerTest = Start-Process -FilePath "ollama" -ArgumentList "serve --check" -NoNewWindow -PassThru -ErrorAction SilentlyContinue
if ($ServerTest.ExitCode -ne 0) {
    Write-Host "📡 Server Ollama non attivo. Avvio server in background..."
    Start-Process -FilePath "ollama" -ArgumentList "serve" -NoNewWindow
    Start-Sleep -Seconds 5
    Write-Host "✅ Server Ollama avviato"
} else {
    Write-Host "✅ Server Ollama già attivo"
}

# 3️⃣ Pull del modello Nemotron-3-Super (cloud)
Write-Host "🌩️ Scarico modello Nemotron-3-Super..."
try {
    ollama pull nemotron-3-super:cloud
    Write-Host "✅ Modello Nemotron pronto"
} catch {
    Write-Host "⚠️ Attenzione: impossibile scaricare il modello. Verifica connessione e server."
}

# 4️⃣ Launch Nemotron-3-Super in SuiteV17
Write-Host "🧠 Lancio Nemotron-3-Super in SuiteV17..."
Start-Process -FilePath "ollama" -ArgumentList "launch openclaw --model nemotron-3-super:cloud" -NoNewWindow

Write-Host "✅ Flusso completato. SuiteV17 pronto all'uso con Nemotron-3-Super!" -ForegroundColor Green
Write-Host "📌 Se il modello non risponde, chiudi e riapri il terminale o verifica server Ollama"