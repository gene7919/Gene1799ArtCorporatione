
@echo off
cls
echo =========================================
echo  SUITEV17 PLATFORM - STARTER
echo =========================================
echo.

cd /d C:\SuiteV17

:: Check Python
set PYTHONPATH=%cd%src;%PYTHONPATH%
python --version > nul 2>&1
if errorlevel 1 (
    echo ERRORE: Python non trovato
    exit /b 1
)

:: Start SuiteV17
echo Avvio SuiteV17...
python src/suitev17/suitev17_resilient_master.py

pause
