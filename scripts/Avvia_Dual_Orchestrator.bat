@echo off
chcp 65001 > nul
title SuiteV17 - Dual Orchestrator System
cd /d C:\SuiteV17

echo ============================================================
echo    SuiteV17 Dual Orchestrator System
echo ============================================================
echo.
echo  Orchestrator 1: Unified Orchestrator (Porta 9001)
echo  Orchestrator 2: Workflow Orchestrator (Porta 9002)
echo.
echo ============================================================
echo.

:: Check Python
set PYTHONPATH=%cd%src;%PYTHONPATH%
python --version > nul 2>&1
if errorlevel 1 (
    echo [ERRORE] Python non trovato!
    pause
    exit /b 1
)

echo [INFO] Installazione dipendenze...
pip install flask flask-cors psutil aiohttp numpy requests schedule -q 2>nul
echo [OK] Dipendenze pronte.
echo.

:: Start Unified Orchestrator
echo [INFO] Avvio Unified Orchestrator (Porta 9001)...
start /B python synaptic_orchestrator.py > logs\orch_9001.log 2>&1
if errorlevel 1 (
    echo [ERRORE] Avvio Unified Orchestrator fallito!
    pause
    exit /b 1
)
timeout /t 3 > nul
echo [OK] Unified Orchestrator avviato.
echo.

:: Start Workflow Orchestrator  
echo [INFO] Avvio Workflow Orchestrator (Porta 9002)...
start /B python workflow_orchestrator.py > logs\orch_9002.log 2>&1
if errorlevel 1 (
    echo [ERRORE] Avvio Workflow Orchestrator fallito!
    pause
    exit /b 1
)
timeout /t 3 > nul
echo [OK] Workflow Orchestrator avviato.
echo.

echo ============================================================
echo  Sistema avviato con successo!
echo.
echo  Dashboard: http://localhost:9001
echo  Workflow:  http://localhost:9002/api
echo.
echo  Entrambi gli orchestratori sono in esecuzione.
echo ============================================================
echo.

:: Open dashboard
start http://localhost:9001

echo Premi un tasto per arrestare tutto...
pause > nul

:: Shutdown
echo.
echo [INFO] Arresto orchestratori...
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *orchestrator*" 2>nul
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *Unified*" 2>nul
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *Workflow*" 2>nul
timeout /t 2 > nul
echo [OK] Orchestrator arrestati.
