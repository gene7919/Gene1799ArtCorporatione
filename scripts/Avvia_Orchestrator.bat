@echo off
chcp 65001 > nul
title SuiteV17 Synaptic Orchestrator
cd /d C:\SuiteV17

echo ==========================================
echo    SuiteV17 Synaptic Orchestrator v2.0
echo ==========================================
echo.

:: Verifica Python
python --version > nul 2>&1
if errorlevel 1 (
    echo [ERRORE] Python non trovato!
    pause
    exit /b 1
)

:: Installazione dipendenze se necessario
echo [INFO] Verifica dipendenze...
pip list | findstr "flask" > nul || pip install flask flask-cors psutil requests -q

echo [INFO] Avvio Orchestrator...
echo [INFO] Dashboard: http://localhost:9001
echo.

start /B python orchestrator_master.py

timeout /t 3 > nul

echo [OK] Orchestrator avviato!
echo [INFO] Apertura dashboard...

start http://localhost:9001

echo.
echo Premi un tasto per fermare tutto...
pause > nul

:: Arresto pulito
echo [INFO] Arresto servizi...
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *orchestrator*" 2> nul

echo [OK] Servizi arrestati.
timeout /t 2 > nul

