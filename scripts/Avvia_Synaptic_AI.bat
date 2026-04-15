@echo off
chcp 65001 > nul
title SuiteV17 Synaptic AI Orchestrator v3.0
cd /d C:\SuiteV17

echo ============================================================
echo    SuiteV17 Synaptic AI Orchestrator v3.0
echo ============================================================
echo.
echo  ?? AI Cloud: Groq + OpenAI + Claude
echo  ?? Synaptic Agents: Auto-training
echo  ? Performance: Fluidity Optimization
echo.
echo ============================================================
echo.

:: Verifica Python
python --version > nul 2>&1
if errorlevel 1 (
    echo [ERRORE] Python non trovato!
    pause
    exit /b 1
)

:: Verifica dipendenze
echo [INFO] Verifica dipendenze...
pip list | findstr "flask" > nul || (
    echo [INFO] Installazione dipendenze...
    pip install flask flask-cors psutil requests aiohttp -q
)
pip list | findstr "groq" > nul || pip install groq -q 2> nul

echo [OK] Dipendenze pronte.
echo.
echo [INFO] Avvio Synaptic Orchestrator...
echo [INFO] Dashboard: http://localhost:9001
echo.

:: Avvia orchestrator
start /B python synaptic_orchestrator.py

timeout /t 4 > nul

echo [OK] Orchestrator avviato!
echo [INFO] Apertura dashboard nel browser...
echo.
start http://localhost:9001

echo ============================================================
echo  Comandi disponibili:
echo    - Gestione servizi con pulsanti Start/Stop
echo    - AI Cloud Generator per testare l'intelligenza artificiale
echo    - Creazione agenti sinaptici con auto-addestramento
echo    - Monitoraggio performance in tempo reale
echo ============================================================
echo.
echo Premi un tasto per arrestare tutto...
pause > nul

:: Arresto
echo.
echo [INFO] Arresto servizi...
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *orchestrator*" 2> nul

echo [OK] Servizi arrestati.
timeout /t 2 > nul
