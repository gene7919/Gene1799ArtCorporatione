@echo off
title SuiteV17 - Avvio Rapido
echo ==========================================
echo  SUITEV17 - Sistema Avviato
echo ==========================================
cd /d C:\SuiteV17
echo.
echo [1/3] Avvio Gateway...
start "Gateway" cmd /k "node gateway.js"
timeout /t 2 /nobreak >nul
echo.
echo [2/3] Avvio Monitor...
start "Monitor" cmd /k "python agent_orchestratore.py monitor"
timeout /t 2 /nobreak >nul
echo.
echo [3/3] Stato iniziale:
python agent_orchestratore.py status
echo.
echo ==========================================
echo  SUITE OPERATIVA!
echo  Gateway: http://localhost:8080
echo ==========================================
pause