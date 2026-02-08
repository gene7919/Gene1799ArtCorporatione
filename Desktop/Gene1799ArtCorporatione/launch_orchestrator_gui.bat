@echo off
REM Gene1799 Orchestrator GUI - Desktop Launcher
REM Starts the GPU-accelerated orchestration interface

setlocal enabledelayedexpansion

title Gene1799 Orchestrator GUI

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python not found!
    echo Please install Python 3.9+
    pause
    exit /b 1
)

REM Navigate to project directory
cd /d "%~dp0"

REM Check if GUI file exists
if not exist "orchestrator_gui.py" (
    echo Error: orchestrator_gui.py not found!
    pause
    exit /b 1
)

REM Check and install required packages
echo Checking dependencies...
python -m pip install psutil -q 2>nul
if %errorlevel% neq 0 (
    echo Installing dependencies...
    python -m pip install psutil
)

REM Launch the GUI
echo Starting Gene1799 Orchestrator GUI...
python orchestrator_gui.py

pause
