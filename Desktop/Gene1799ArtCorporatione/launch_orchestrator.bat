@echo off
REM Gene1799 Orchestrator Launcher - Windows Batch
REM Starts the master orchestrator for Gene1799 platform

setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║  🎼 GENE1799 MASTER ORCHESTRATOR                      ║
echo ║  Service & Agent Orchestration System                 ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python not found! Please install Python 3.9+
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "orchestrator.py" (
    echo ❌ orchestrator.py not found!
    echo Please run this from Gene1799ArtCorporatione directory
    pause
    exit /b 1
)

echo ✅ Environment verified
echo.
echo 🚀 Starting Python orchestrator...
echo.

REM Run the orchestrator
python orchestrator.py

pause
