@echo off
chcp 65001 > nul
cls

echo  ███████╗██╗   ██╗██╗████████╗███████╗██╗  ██╗██╗   ██╗
echo  ██╔════╝██║   ██║██║╚══██╔══╝██╔════╝██║  ██║██║   ██║
echo  ███████╗██║   ██║██║   ██║   █████╗  ███████║██║   ██║
echo  ╚════██║██║   ██║██║   ██║   ██╔══╝  ██╔══██║╚██╗ ██╔╝
echo  ███████║╚██████╔╝██║   ██║   ███████╗██║  ██║ ╚████╔╝
echo  ╚══════╝ ╚═════╝ ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝  ╚═══╝
echo.
echo              CONTROL ROOM - Console Unificata
echo =========================================================
echo.

REM Menu scelta
echo  [1] Avvia Control Room Desktop
echo  [2] Avvia Solo Terminal (PM2)
echo  [3] Verifica Moduli
echo  [4] Installa/Aggiorna Dipendenze
echo  [5] Build Eseguibile
echo  [Q] Esci
echo.

choice /C 12345Q /N /M "Seleziona opzione: "

if errorlevel 6 goto :EOF
if errorlevel 5 goto BUILD
if errorlevel 4 goto INSTALL
if errorlevel 3 goto CHECK
if errorlevel 2 goto TERMINAL
if errorlevel 1 goto CONTROLROOM

:CONTROLROOM
cd /d "C:\\SuiteV17\\ElectronApp"
start "" "Start-ControlRoom.bat"
goto :EOF

:TERMINAL
cd /d "C:\\SuiteV17"
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoExit','-Command','Write-Host \`"SuiteV17 Terminal\`" -Fore Cyan; pm2 status'"
goto :EOF

:CHECK
cd /d "C:\\SuiteV17\\ElectronApp"
node scripts\\check-modules.js
pause
goto :EOF

:INSTALL
cd /d "C:\\SuiteV17\\ElectronApp"
npm install
cd ..\\TokenModule && npm install
cd ..\\BrowserModule && npm install
cd ..\\VideoWorker && npm install
echo.
echo [OK] Tutte le dipendenze installate!
pause
goto :EOF

:BUILD
cd /d "C:\\SuiteV17\\ElectronApp"
npm run build:win
echo.
echo [OK] Build completata in dist\
pause
goto :EOF
