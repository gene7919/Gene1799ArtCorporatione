# Gene1799 Enhanced System - EXE Builder Launcher
# Script PowerShell per creare l'installer con un click

Write-Host "`n"
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║       ✨ Gene1799 Enhanced System - EXE Builder Launcher ✨   ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║            Creiamo il tuo installer in pochi click!            ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "`n"

# STEP 1: Controlla directory
Write-Host "[STEP 1]" -ForegroundColor Blue -NoNewline
Write-Host " Controllo directory..." -ForegroundColor White
$basePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildScript = Join-Path $basePath "build_executable.py"

if (-not (Test-Path $buildScript)) {
    Write-Host "✗ Script build_executable.py non trovato!" -ForegroundColor Red
    Write-Host "  Assicurati di essere nella cartella giusta: c:\Users\gene1\Desktop\gene1799artcorporatione" -ForegroundColor Yellow
    Read-Host "Premi INVIO per uscire"
    exit 1
}

Write-Host "✓ Directory OK" -ForegroundColor Green

# STEP 2: Controlla Python
Write-Host "[STEP 2]" -ForegroundColor Blue -NoNewline
Write-Host " Controllo Python..." -ForegroundColor White
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ Python trovato: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Python non trovato!" -ForegroundColor Red
    Write-Host "  Scarica Python 3.8+ da python.org e reinstalla" -ForegroundColor Yellow
    Read-Host "Premi INVIO per uscire"
    exit 1
}

# STEP 3: Installa PyInstaller
Write-Host "[STEP 3]" -ForegroundColor Blue -NoNewline
Write-Host " Verifica PyInstaller..." -ForegroundColor White
try {
    python -c "import PyInstaller; print(PyInstaller.__version__)" | Out-Null
    Write-Host "✓ PyInstaller già installato" -ForegroundColor Green
} catch {
    Write-Host "⚠ PyInstaller non trovato, installo..." -ForegroundColor Yellow
    python -m pip install pyinstaller -q
    Write-Host "✓ PyInstaller installato" -ForegroundColor Green
}

# STEP 4: Installa dipendenze
Write-Host "[STEP 4]" -ForegroundColor Blue -NoNewLine
Write-Host " Installa dipendenze..." -ForegroundColor White
$packages = @("psutil", "aiohttp")
foreach ($package in $packages) {
    try {
        python -c "import $package" 2>&1 | Out-Null
        Write-Host "  [OK] $package disponibile" -ForegroundColor Green
    }
    catch {
        Write-Host "  [INSTALL] $package..." -ForegroundColor Yellow
        python -m pip install $package -q
        Write-Host "  [OK] $package installato" -ForegroundColor Green
    }
}

# STEP 5: Avvia il build
Write-Host "[STEP 5]" -ForegroundColor Blue -NoNewline
Write-Host " Avvio build..." -ForegroundColor White
Write-Host "`n"

Write-Host "[WAIT] Questo richiede 2-5 minuti... Pazienza!" -ForegroundColor Yellow
Write-Host "`n"

# Esegui lo script Python
& python $buildScript

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n"
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green -BackgroundColor Black
    Write-Host "║                   ✓ BUILD COMPLETATO! ✓                       ║" -ForegroundColor Green
    Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║                                                                ║" -ForegroundColor Green
    Write-Host "║  📁 Cartella di output: dist/                                 ║" -ForegroundColor Green
    Write-Host "║                                                                ║" -ForegroundColor Green
    Write-Host "║  TROVERai:                                                     ║" -ForegroundColor Green
    Write-Host "║  ├─ Gene1799_Enhanced.exe (Applicazione)                      ║" -ForegroundColor Green
    Write-Host "║  ├─ Gene1799_v2.0_Installer.exe (Setup)                       ║" -ForegroundColor Green
    Write-Host "║  └─ RUN_Gene1799.bat (Query veloce)                           ║" -ForegroundColor Green
    Write-Host "║                                                                ║" -ForegroundColor Green
    Write-Host "║  🚀 COME USARE:                                                ║" -ForegroundColor Green
    Write-Host "║  1. Apri la cartella 'dist'                                   ║" -ForegroundColor Green
    Write-Host "║  2. Doppio click su 'Gene1799_v2.0_Installer.exe'             ║" -ForegroundColor Green
    Write-Host "║  3. Segui il wizard di installazione                          ║" -ForegroundColor Green
    Write-Host "║  4. Fine! Sistema pronto all'uso                              ║" -ForegroundColor Green
    Write-Host "║                                                                ║" -ForegroundColor Green
    Write-Host "║  ✨ ALTERNATIVA: Versione Portable                             ║" -ForegroundColor Green
    Write-Host "║  1. Apri 'dist/Gene1799_Enhanced'                             ║" -ForegroundColor Green
    Write-Host "║  2. Doppio click su 'RUN_Gene1799.bat'                        ║" -ForegroundColor Green
    Write-Host "║  3. Sistema avviato istantaneamente!                          ║" -ForegroundColor Green
    Write-Host "║                                                                ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "`n"
    
    # Apri la cartella
    Write-Host "Apro la cartella di output..." -ForegroundColor Cyan
    Start-Process (Join-Path $basePath "dist")
    
    Write-Host "`nBuild completato! 🎉" -ForegroundColor Green
    Read-Host "`nPremi INVIO per chiudere"
} else {
    Write-Host "`n"
    Write-Host "✗ Errore durante il build!" -ForegroundColor Red
    Write-Host "Controlla i messaggi di errore sopra." -ForegroundColor Yellow
    Read-Host "`nPremi INVIO per chiudere"
    exit 1
}
