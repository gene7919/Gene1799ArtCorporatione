@echo off
title SuiteV17 Control Center
echo ==========================================
echo   SUITEV17 CONTROL CENTER
echo ==========================================
echo.
cd /d C:\SuiteV17
echo [1/3] Avvio API Service Control...
start "SuiteV17 API" cmd /k "cd /d C:\SuiteV17 && python service_api.py"
timeout /t 4 /nobreak > nul
echo API avviata su porta 9000
echo.
echo [2/3] Apertura Dashboard...
start C:\SuiteV17\dashboard.html
echo Dashboard aperta
echo.
echo ==========================================
echo   SUITE PRONTA - I pulsanti sono attivi!
echo ==========================================
echo.
pause
