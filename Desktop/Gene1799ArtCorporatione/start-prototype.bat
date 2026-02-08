@echo off
REM GENE1799 LOCAL PROTOTYPE LAUNCHER - Windows
REM Avvia il sistema completo come prototipo locale

setlocal enabledelayedexpansion

cls
echo.
echo ╔═══════════════════════════════════════════════════════╗
echo ║   GENE1799 LOCAL PROTOTYPE LAUNCHER                   ║
echo ║   Production-ready system on localhost                ║
echo ╚═══════════════════════════════════════════════════════╝
echo.

REM Check prerequisites
echo [*] Checking prerequisites...

node --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js not found
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do echo [OK] Node.js %%i

npm --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm not found
    exit /b 1
)
echo [OK] npm installed

REM Check directories
if not exist "backend\src" (
    echo [ERROR] backend\src directory not found
    exit /b 1
)
echo [OK] backend\src found

if not exist "frontend" (
    echo [ERROR] frontend directory not found
    exit /b 1
)
echo [OK] frontend found

if not exist "telegram-bot" (
    echo [ERROR] telegram-bot directory not found
    exit /b 1
)
echo [OK] telegram-bot found

REM Setup environment
echo.
echo [*] Setting up environment...

if not exist "backend\.env" (
    if exist "backend\.env.example" (
        copy "backend\.env.example" "backend\.env" >nul
        echo [!] Created backend\.env from template
        echo [!] Please configure backend\.env with your credentials
    )
)
echo [OK] Environment configured

REM Install dependencies
echo.
echo [*] Installing dependencies...
call npm install >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies
    exit /b 1
)
echo [OK] Dependencies installed

REM Launch prototype
echo.
echo ╔═══════════════════════════════════════════════════════╗
echo ║              LAUNCHING PROTOTYPE SYSTEM                ║
echo ╚═══════════════════════════════════════════════════════╝
echo.

echo [INFO] Starting GENE1799 Local Prototype...
echo.
echo Services starting:
echo.
echo   📊 Dashboard       → http://localhost:3000
echo   🌐 Web3 dApps      → http://localhost:3000/web3-dapps-dashboard.html
echo   🔌 Backend API     → http://localhost:3001
echo   🤖 Telegram Bot    → Polling active
echo.

REM Run prototype launcher
node start-prototype.js

if errorlevel 1 (
    echo [ERROR] Prototype launcher failed
    pause
    exit /b 1
)

pause
