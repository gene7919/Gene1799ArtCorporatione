@echo off
chcp 65001 > nul
title SuiteV17 Unified Orchestrator v4.0
cd /d C:\SuiteV17

echo ============================================================
echo    SuiteV17 Unified Orchestrator v4.0
echo ============================================================
echo.
echo  [AI] Cloud: Groq + OpenAI + Anthropic
echo  [AGENT] Synaptic: Auto-training System
echo  [PERF] Fluidity Optimization
echo.
echo ============================================================

python --version > nul 2>&1
if errorlevel 1 (
    echo [ERRORE] Python non trovato!
    pause
    exit /b 1
)

echo [INFO] Verifica dipendenze...
pip install flask flask-cors psutil aiohttp numpy requests -q 2>nul
echo [OK] Dipendenze pronte.

echo [INFO] Avvio Orchestrator...
echo [INFO] Dashboard: http://localhost:9001

start /B python synaptic_orchestrator.py
timeout /t 4 > nul

echo [OK] Orchestrator avviato!
start http://localhost:9001

echo.
echo Premi un tasto per arrestare tutto...
pause > nul

echo [INFO] Arresto servizi...
curl -s http://localhost:9001/api/services/stop-all -X POST >nul 2>&1
timeout /t 2 > nul
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *orchestrator*" 2>nul

echo [OK] Servizi arrestati.
timeout /t 2 > nul
