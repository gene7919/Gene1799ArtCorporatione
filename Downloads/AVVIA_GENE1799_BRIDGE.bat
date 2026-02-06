@echo off
title Gene1799 Universal Bridge
color 0B

echo.
echo ╔══════════════════════════════════════════════════════════════════╗
echo ║                                                                  ║
echo ║              GENE1799 UNIVERSAL BRIDGE SYSTEM                   ║
echo ║              Collega TUTTI i dati D:\ e E:\                     ║
echo ║                                                                  ║
echo ╚══════════════════════════════════════════════════════════════════╝
echo.
echo.
echo 🔍 Scansione e collegamento dati in corso...
echo.

cd /d D:\Gene1799\Explorer

:: Controlla PowerShell
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    pwsh.exe -ExecutionPolicy Bypass -File "Gene1799_Universal_Bridge.ps1"
) else (
    powershell.exe -ExecutionPolicy Bypass -File "Gene1799_Universal_Bridge.ps1"
)

echo.
pause
