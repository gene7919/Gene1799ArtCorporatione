@echo off
REM ============================================================================
REM GENE1799 SETUP AUTOMATION - LAUNCHER
REM Windows Batch Script
REM ============================================================================

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  GENE1799 ART CORPORATIONE - SETUP LAUNCHER                       ║
echo ║  Interactive Setup Wizard                                          ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

REM Check PowerShell
powershell -Command "Write-Host 'OK'" > nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ PowerShell non trovato!
    echo   Installa PowerShell Core da: https://github.com/PowerShell/PowerShell/releases
    pause
    exit /b 1
)

REM Ask for mode
echo.
echo Seleziona modalità di setup:
echo.
echo 1 - Setup Completo (Automatico)
echo 2 - Setup Interattivo (Con domande)
echo 3 - Solo GitHub push
echo 4 - Solo Render deploy
echo 5 - Exit
echo.

set /p choice="Scelta (1-5): "

if "%choice%"=="1" (
    echo.
    echo ✓ Avviando setup AUTOMATICO...
    echo.
    powershell -ExecutionPolicy Bypass -File "setup-automation.ps1" -InteractiveMode $false
) else if "%choice%"=="2" (
    echo.
    echo ✓ Avviando setup INTERATTIVO...
    echo.
    powershell -ExecutionPolicy Bypass -File "setup-automation.ps1" -InteractiveMode $true
) else if "%choice%"=="3" (
    echo.
    echo ✓ Push su GitHub...
    echo.
    powershell -ExecutionPolicy Bypass -File "setup-automation.ps1" -SkipRender -SkipWordPress -InteractiveMode $false
) else if "%choice%"=="4" (
    echo.
    echo ✓ Setup Render...
    echo.
    powershell -ExecutionPolicy Bypass -File "setup-automation.ps1" -SkipGitHub -InteractiveMode $true
) else (
    echo Exit.
    exit /b 0
)

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Setup completato!                                                 ║
echo ║                                                                    ║
echo ║  Prossimi step:                                                    ║
echo ║  1. Leggi SETUP_GUIDE.md                                           ║
echo ║  2. Vai su Render: https://dashboard.render.com                    ║
echo ║  3. Configura WordPress                                            ║
echo ║  4. Setup DNS su Porkbun                                           ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

pause
