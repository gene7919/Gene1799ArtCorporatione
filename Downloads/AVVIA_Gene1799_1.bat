@echo off
chcp 65001 >nul
title Gene1799 MegaSystem Launcher
color 0B

echo.
echo ╔══════════════════════════════════════════════════════════════════╗
echo ║                                                                  ║
echo ║          GENE1799 MEGA SYSTEM LAUNCHER                          ║
echo ║          Art Corporation - License: 16/L4090879L                ║
echo ║                                                                  ║
echo ╚══════════════════════════════════════════════════════════════════╝
echo.

:: Check PowerShell 7
where pwsh >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [!] PowerShell 7 non trovato. Installazione...
    echo.
    echo     Installa manualmente:
    echo     winget install Microsoft.PowerShell
    echo.
    echo     oppure scarica da:
    echo     https://github.com/PowerShell/PowerShell/releases
    echo.
    pause
    exit /b 1
)

echo [OK] PowerShell 7 trovato
echo.

:: Menu
echo  MENU AVVIO:
echo  ─────────────────────────────────────────────
echo.
echo    [1] Avvia Dashboard Interattiva (GUI)
echo    [2] Inizializza Sistema (primo avvio)
echo    [3] Status Sistema
echo    [4] Health Check
echo    [5] Backup Sistema
echo    [6] Apri PowerShell nella cartella
echo    [0] Esci
echo.
echo  ─────────────────────────────────────────────
echo.

set /p choice=  Scegli opzione: 

if "%choice%"=="1" (
    echo.
    echo  Avvio Dashboard...
    pwsh -NoExit -ExecutionPolicy Bypass -File "%~dp0Gene1799_MegaSystem.ps1" -Mode GUI
    goto :end
)

if "%choice%"=="2" (
    echo.
    echo  Inizializzazione sistema...
    pwsh -NoExit -ExecutionPolicy Bypass -File "%~dp0Gene1799_MegaSystem.ps1" -Mode INIT
    goto :end
)

if "%choice%"=="3" (
    echo.
    echo  Mostra status...
    pwsh -ExecutionPolicy Bypass -File "%~dp0Gene1799_MegaSystem.ps1" -Mode STATUS
    pause
    goto :end
)

if "%choice%"=="4" (
    echo.
    echo  Health Check...
    pwsh -ExecutionPolicy Bypass -File "%~dp0Gene1799_MegaSystem.ps1" -Mode HEAL
    pause
    goto :end
)

if "%choice%"=="5" (
    echo.
    echo  Backup Sistema...
    pwsh -ExecutionPolicy Bypass -File "%~dp0Gene1799_MegaSystem.ps1" -Mode BACKUP
    pause
    goto :end
)

if "%choice%"=="6" (
    echo.
    echo  Apertura PowerShell...
    start pwsh -NoExit -WorkingDirectory "%~dp0"
    goto :end
)

if "%choice%"=="0" (
    echo.
    echo  Arrivederci!
    timeout /t 2 >nul
    exit /b 0
)

echo.
echo  [!] Opzione non valida
pause

:end
