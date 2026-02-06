@echo off
:: GENE1799 AI SYSTEM - INSTALLER AUTOMATICO
:: Doppio click per installare!

title Gene1799 Installer
color 0B

echo.
echo ╔══════════════════════════════════════════════════════════════════╗
echo ║                                                                  ║
echo ║                     GENE1799 AI SYSTEM                           ║
echo ║                   Installer Automatico v1.0                      ║
echo ║                                                                  ║
echo ╚══════════════════════════════════════════════════════════════════╝
echo.
echo.
echo 🚀 Avvio installazione...
echo.

:: Controlla se PowerShell 7 è disponibile
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ PowerShell 7 trovato
    pwsh.exe -ExecutionPolicy Bypass -File "%~dp0Gene1799_Installer.ps1"
) else (
    echo ⚠ PowerShell 7 non trovato, uso PowerShell 5
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Gene1799_Installer.ps1"
)

echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
pause
