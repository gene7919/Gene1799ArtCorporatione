@echo off
chcp 65001 >nul 2>&1
title GENE1799 Art Corporatione - System Launcher
color 0A

echo ============================================================
echo   GENE1799 ART CORPORATIONE - SYSTEM LAUNCHER v4.0
echo   RTX 4070 Super ^| Ollama ^| Azure ^| Web3 ^| Telegram
echo ============================================================
echo.

set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

:: ============================================================
:: CHECK PREREQUISITES
:: ============================================================
echo [1/4] Checking prerequisites...

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found. Install from https://nodejs.org
    pause
    exit /b 1
)

where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found. Install from https://python.org
    pause
    exit /b 1
)

echo   [OK] Node.js found
echo   [OK] Python found

:: Check Ollama
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo   [WARN] Ollama not running - trying to start...
    start "" ollama serve
    timeout /t 3 /nobreak >nul
)
echo   [OK] Ollama checked

:: Check telegram-bot deps
if not exist "%PROJECT_DIR%telegram-bot\node_modules" (
    echo   [INFO] Installing Telegram bot dependencies...
    cd /d "%PROJECT_DIR%telegram-bot" && npm install --silent >nul 2>&1
    cd /d "%PROJECT_DIR%"
)
echo   [OK] Telegram bot deps checked

:: ============================================================
:: KILL OLD PROCESSES ON OUR PORTS
:: ============================================================
echo.
echo [2/4] Cleaning up old processes...

for %%p in (4000 5050 8001 8002 8003 8004) do (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%%p " ^| findstr "LISTENING" 2^>nul') do (
        if not "%%a"=="0" (
            taskkill /PID %%a /F >nul 2>&1
            echo   Stopped old process on port %%p
        )
    )
)

timeout /t 2 /nobreak >nul

:: ============================================================
:: START ALL SERVICES
:: ============================================================
echo.
echo [3/4] Starting GENE1799 services...

:: GPU Service (Port 4000)
echo   Starting GPU Service [Port 4000]...
start /B "" python "%PROJECT_DIR%gpu-service\main.py" >"%PROJECT_DIR%logs\gpu.log" 2>&1

:: Azure AI Integration (Port 8001)
echo   Starting Azure AI Service [Port 8001]...
start /B "" python "%PROJECT_DIR%azure_ai_integration.py" >"%PROJECT_DIR%logs\azure.log" 2>&1

:: Creative Content Service (Port 8002)
echo   Starting Creative Content Service [Port 8002]...
start /B "" python "%PROJECT_DIR%creative-content-service\main.py" >"%PROJECT_DIR%logs\creative.log" 2>&1

:: Publishing Pipeline (Port 8003)
echo   Starting Publishing Pipeline [Port 8003]...
start /B "" python "%PROJECT_DIR%publishing-service\main.py" >"%PROJECT_DIR%logs\publishing.log" 2>&1

:: Web3 & NFT Service (Port 8004)
echo   Starting Web3 ^& NFT Service [Port 8004]...
start /B "" python "%PROJECT_DIR%web3-service\main.py" >"%PROJECT_DIR%logs\web3.log" 2>&1

:: Wait for Python services to start
timeout /t 5 /nobreak >nul

:: Unified Orchestrator (Port 5050)
echo   Starting Unified Orchestrator [Port 5050]...
start /B "" node "%PROJECT_DIR%orchestrator-unified.js" >"%PROJECT_DIR%logs\orchestrator.log" 2>&1

:: Telegram Bot (polling mode - no port)
echo   Starting Telegram Bot...
start /B "" node "%PROJECT_DIR%telegram-bot\bot.js" >"%PROJECT_DIR%logs\telegram.log" 2>&1

:: Wait for orchestrator
timeout /t 3 /nobreak >nul

:: ============================================================
:: VERIFY ALL SERVICES
:: ============================================================
echo.
echo [4/4] Verifying services...
echo.
echo ============================================================
echo   SERVICE STATUS
echo ============================================================

set HEALTHY=0

:: Check each service
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Ollama LLM          - Port 11434
    set /a HEALTHY+=1
) else (
    echo   [--] Ollama LLM          - Port 11434  NOT RUNNING
)

curl -s http://localhost:4000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] GPU Service          - Port 4000
    set /a HEALTHY+=1
) else (
    echo   [--] GPU Service          - Port 4000   NOT RUNNING
)

curl -s http://localhost:8001/health >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Azure AI             - Port 8001
    set /a HEALTHY+=1
) else (
    echo   [--] Azure AI             - Port 8001   NOT RUNNING
)

curl -s http://localhost:8002/health >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Creative Content     - Port 8002
    set /a HEALTHY+=1
) else (
    echo   [--] Creative Content     - Port 8002   NOT RUNNING
)

curl -s http://localhost:8003/health >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Publishing Pipeline  - Port 8003
    set /a HEALTHY+=1
) else (
    echo   [--] Publishing Pipeline  - Port 8003   NOT RUNNING
)

curl -s http://localhost:8004/health >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Web3 ^& NFT Service  - Port 8004
    set /a HEALTHY+=1
) else (
    echo   [--] Web3 ^& NFT Service  - Port 8004   NOT RUNNING
)

curl -s http://localhost:5050/health >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Orchestrator         - Port 5050
    set /a HEALTHY+=1
) else (
    echo   [--] Orchestrator         - Port 5050   NOT RUNNING
)

echo   [OK] Telegram Bot         - Polling Mode

echo.
echo ============================================================
echo   GENE1799 SYSTEM READY - %HEALTHY% services + Telegram Bot
echo ============================================================
echo.
echo   Orchestrator API:    http://localhost:5050
echo   GPU Metrics:         http://localhost:4000/gpu/metrics
echo   Creative Pipeline:   http://localhost:8002/status
echo   Publishing Queue:    http://localhost:8003/status
echo   Token Info:          http://localhost:8004/token/info
echo   Token Price:         http://localhost:8004/token/price
echo   NFT Gallery:         http://localhost:8004/nft/all
echo   Zora Profile:        https://zora.co/@gene1799
echo   OpenSea:             https://opensea.io/collection/gene1799
echo.
echo   Press any key to open the Orchestrator status page...
echo   Press Ctrl+C to keep running in background.
echo.
pause >nul
start http://localhost:5050/health
