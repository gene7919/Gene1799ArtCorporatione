@echo off
REM ════════════════════════════════════════════════════════════════════════════════
REM GENE1799 v4.0 - COMPLETE INSTALLER FOR WINDOWS
REM Web3 + NFT + Telegram + GPU + AI Services
REM ════════════════════════════════════════════════════════════════════════════════

setlocal enabledelayedexpansion

cls
color 0B
title GENE1799 v4.0 - Complete Installer

set "INSTALL_DRIVE=%systemdrive%"
set "INSTALL_PATH=%INSTALL_DRIVE%\GENE1799"
set "DOWNLOAD_URL=https://github.com/gene7919/Gene1799ArtCorporatione/archive/refs/heads/main.zip"

echo.
echo ============================================================
echo   GENE1799 ART CORPORATIONE v4.0 - COMPLETE INSTALLER
echo   Web3 + NFT + Telegram + GPU + AI Services
echo ============================================================
echo.
echo   This will install:
echo     10 Independent services (GPU, Web3, Creative, etc.)
echo     Telegram Bot with NFT notifications
echo     Web3 crypto portfolio + NFT gallery
echo     Unified Orchestrator with 23+ AI agents
echo.
echo   Installation location: %INSTALL_PATH%
echo.

REM Check prerequisites
echo [*] Checking prerequisites...

where git >nul 2>&1
if errorlevel 1 (
    echo [!] Git not found. Please install Git first.
    echo Download from: https://git-scm.com/downloads
    pause
    exit /b 1
)
echo [+] Git found

where node >nul 2>&1
if errorlevel 1 (
    echo [!] Node.js not found. Please install Node.js first.
    echo Download from: https://nodejs.org/
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do set NODE_VER=%%i
echo [+] Node.js %NODE_VER%

where npm >nul 2>&1
if errorlevel 1 (
    echo [!] npm not found
    exit /b 1
)
for /f "tokens=*" %%i in ('npm --version') do set NPM_VER=%%i
echo [+] npm %NPM_VER%

where docker >nul 2>&1
if errorlevel 1 (
    echo [!] Docker not found. Please install Docker Desktop first.
    echo Download from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo [+] Docker found

where python >nul 2>&1
if errorlevel 1 (
    echo [!] Python not found (optional but recommended)
) else (
    for /f "tokens=*" %%i in ('python --version') do set PYTHON_VER=%%i
    echo [+] %PYTHON_VER%
)

echo.
echo [*] Prerequisites verified!
echo.

REM Create installation directory
echo [*] Creating installation directory...
if not exist "%INSTALL_PATH%" (
    mkdir "%INSTALL_PATH%"
    echo [+] Created: %INSTALL_PATH%
) else (
    echo [+] Directory already exists: %INSTALL_PATH%
)

REM Create subdirectories
for %%D in (
    backend
    frontend
    gpu-service
    telegram-bot
    web3-service
    creative-content-service
    publishing-service
    ai-agent
    logs
    data
    config
    docs
    media
    bin\launchers
    bin\services
    scripts
    temp
) do (
    if not exist "%INSTALL_PATH%\%%D" mkdir "%INSTALL_PATH%\%%D"
)
echo [+] Directory structure created

REM Clone or update repository
echo.
echo [*] Downloading GENE1799 files...

if exist "%INSTALL_PATH%\.git" (
    echo [*] Repository exists, pulling updates...
    cd /d "%INSTALL_PATH%"
    git pull origin main >nul 2>&1
) else (
    echo [*] Cloning repository...
    git clone %DOWNLOAD_URL% "%INSTALL_PATH%\temp-clone" >nul 2>&1
    if exist "%INSTALL_PATH%\temp-clone" (
        move "%INSTALL_PATH%\temp-clone\Gene1799ArtCorporatione-main\*" "%INSTALL_PATH%\" >nul 2>&1
        rmdir /s /q "%INSTALL_PATH%\temp-clone"
        echo [+] Repository cloned successfully
    )
)

REM Install npm dependencies (root project)
echo.
echo [*] Installing npm dependencies...
cd /d "%INSTALL_PATH%"
call npm install >nul 2>&1
echo [+] Root dependencies installed

REM Install telegram-bot dependencies
echo [*] Installing Telegram bot dependencies...
if exist "%INSTALL_PATH%\telegram-bot\package.json" (
    cd /d "%INSTALL_PATH%\telegram-bot"
    call npm install >nul 2>&1
    echo [+] Telegram bot dependencies installed
) else (
    echo [!] telegram-bot/package.json not found - skipping
)
cd /d "%INSTALL_PATH%"

REM Install Python dependencies
echo.
echo [*] Installing Python dependencies...
where python >nul 2>&1
if %errorlevel% equ 0 (
    python -m pip install --upgrade pip >nul 2>&1
    python -m pip install fastapi uvicorn pydantic requests aiohttp >nul 2>&1
    echo [+] Python base packages installed
    python -m pip install web3 >nul 2>&1
    echo [+] Web3 (blockchain) package installed
    python -m pip install pynvml Pillow >nul 2>&1
    echo [+] GPU monitoring packages installed
    python -m pip install edge-tts >nul 2>&1
    echo [+] Text-to-speech package installed
) else (
    echo [!] Python not found - skipping Python dependencies
    echo     Install Python 3.12+ from https://python.org for full functionality
)

REM Create .env file
echo.
echo [*] Creating configuration file...
if not exist "%INSTALL_PATH%\.env" (
    (
        echo # GENE1799 v4.0 Configuration
        echo NODE_ENV=production
        echo ENVIRONMENT=local-prototype
        echo.
        echo # === SERVICE PORTS ===
        echo OLLAMA_PORT=11434
        echo BACKEND_PORT=3000
        echo FRONTEND_PORT=5173
        echo GPU_SERVICE_PORT=4000
        echo MONGODB_PORT=27017
        echo AZURE_AI_PORT=8001
        echo CREATIVE_PORT=8002
        echo PUBLISHING_PORT=8003
        echo WEB3_PORT=8004
        echo ORCHESTRATOR_PORT=5050
        echo.
        echo # === DATABASE ===
        echo MONGODB_URI=mongodb://admin:gene1799ultra2026@localhost:27017/gene1799_v7
        echo.
        echo # === GPU ===
        echo GPU_ENABLED=true
        echo GPU_TYPE=RTX_4070_SUPER
        echo.
        echo # === WEB3 / BLOCKCHAIN ===
        echo BASE_RPC_URL=https://mainnet.base.org
        echo TOKEN_CONTRACT=0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0
        echo WEB3_SERVICE_URL=http://localhost:8004
        echo.
        echo # === TELEGRAM BOT ===
        echo # Get your bot token from @BotFather on Telegram
        echo BOT_TOKEN=
        echo CHANNEL_ID=
        echo ADMIN_IDS=
        echo.
        echo # === AZURE AI ^(optional^) ===
        echo AZURE_ENDPOINT=
        echo AZURE_PROJECT_ID=
    ) > "%INSTALL_PATH%\.env"
    echo [+] Configuration file created
    echo     IMPORTANT: Edit .env to add your Telegram BOT_TOKEN!
) else (
    echo [+] .env already exists - not overwriting
)

REM Create desktop shortcut
echo.
echo [*] Creating desktop shortcut...
(
    echo [InternetShortcut]
    echo URL=file:///%INSTALL_PATH%\START.bat
) > "%userprofile%\Desktop\GENE1799.url"
echo [+] Desktop shortcut created

REM Create START.bat that uses GENE1799-LAUNCH.bat
echo.
echo [*] Creating startup script...
if exist "%INSTALL_PATH%\GENE1799-LAUNCH.bat" (
    echo [+] GENE1799-LAUNCH.bat already exists
) else (
    (
        echo @echo off
        echo cls
        echo title GENE1799 v4.0 Control Center
        echo color 0A
        echo cd /d "%INSTALL_PATH%"
        echo call GENE1799-LAUNCH.bat
        echo pause
    ) > "%INSTALL_PATH%\START.bat"
    echo [+] Startup script created
)

REM Final summary
echo.
echo ============================================================
echo   INSTALLATION COMPLETE!
echo ============================================================
echo.
echo   Location: %INSTALL_PATH%
echo.
echo   To start GENE1799:
echo     Option 1: Double-click GENE1799-LAUNCH.bat
echo     Option 2: Click desktop shortcut "GENE1799"
echo     Option 3: Run START.bat
echo.
echo   Services (started by launcher):
echo     Ollama LLM          Port 11434
echo     GPU Service          Port 4000
echo     Azure AI             Port 8001
echo     Creative Content     Port 8002
echo     Publishing Pipeline  Port 8003
echo     Web3 + NFT           Port 8004
echo     Orchestrator         Port 5050
echo     Telegram Bot         Polling Mode
echo.
echo   Configuration: %INSTALL_PATH%\.env
echo   IMPORTANT: Set BOT_TOKEN in .env for Telegram bot!
echo.
echo   Quick Links:
echo     Orchestrator:  http://localhost:5050
echo     Token Info:    http://localhost:8004/token/info
echo     Token Price:   http://localhost:8004/token/price
echo     NFT Gallery:   http://localhost:8004/nft/all
echo     GPU Metrics:   http://localhost:4000/gpu/metrics
echo.
echo ============================================================
echo.
pause
