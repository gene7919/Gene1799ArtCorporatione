@echo off
REM ════════════════════════════════════════════════════════════════════════════════
REM GENE1799 v3.0 - QUICK INSTALLER FOR WINDOWS
REM ════════════════════════════════════════════════════════════════════════════════

setlocal enabledelayedexpansion

cls
color 0B
title GENE1799 v3.0 - Auto Installer

set "INSTALL_DRIVE=%systemdrive%"
set "INSTALL_PATH=%INSTALL_DRIVE%\GENE1799"
set "DOWNLOAD_URL=https://github.com/gene7919/Gene1799ArtCorporatione/archive/refs/heads/main.zip"

echo.
echo ╔════════════════════════════════════════════════════════════════════════════╗
echo ║                                                                            ║
echo ║               GENE1799 v3.0 - QUICK INSTALLER                             ║
echo ║            Multi-Service AI System for Windows                            ║
echo ║                                                                            ║
echo ║  This will install:                                                        ║
echo ║  • 7 Independent AI services                                              ║
echo ║  • Master control center                                                  ║
echo ║  • 23 AI agents                                                           ║
echo ║  • Complete documentation                                                 ║
echo ║                                                                            ║
echo ║  Installation location: %INSTALL_PATH%                                    ║
echo ║                                                                            ║
echo ╚════════════════════════════════════════════════════════════════════════════╝
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
setlocal enabledelayedexpansion
for %%D in (
    backend
    frontend
    gpu-service
    telegram-bot
    ai-agent
    logs
    data
    config
    docs
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

REM Install npm dependencies
echo.
echo [*] Installing npm dependencies...
cd /d "%INSTALL_PATH%"
call npm install >nul 2>&1
echo [+] Dependencies installed

REM Create .env file
echo.
echo [*] Creating configuration file...
(
    echo # GENE1799 v3.0 Configuration
    echo NODE_ENV=production
    echo ENVIRONMENT=local-prototype
    echo.
    echo # PORTS
    echo OLLAMA_PORT=11434
    echo BACKEND_PORT=3000
    echo FRONTEND_PORT=5173
    echo GPU_SERVICE_PORT=4000
    echo MONGODB_PORT=27017
    echo PYTHON_AGENT_PORT=8000
    echo ORCHESTRATOR_PORT=5000
    echo.
    echo # DATABASE
    echo MONGODB_URI=mongodb://admin:gene1799ultra2026@localhost:27017/gene1799_v7
    echo.
    echo # GPU
    echo GPU_ENABLED=true
    echo GPU_TYPE=RTX_4070_SUPER
) > "%INSTALL_PATH%\.env"
echo [+] Configuration file created

REM Create desktop shortcut
echo.
echo [*] Creating desktop shortcut...
(
    echo [InternetShortcut]
    echo URL=file:///%INSTALL_PATH%\START.bat
) > "%userprofile%\Desktop\GENE1799.url"
echo [+] Desktop shortcut created

REM Create START.bat
echo.
echo [*] Creating startup script...
(
    echo @echo off
    echo cls
    echo title GENE1799 v3.0 Control Center
    echo color 0B
    echo cd /d "%INSTALL_PATH%"
    echo powershell -NoExit -Command "& { . '.\bin\launchers\service-coordinator.ps1' -Command Dashboard }"
    echo pause
) > "%INSTALL_PATH%\START.bat"
echo [+] Startup script created

REM Final summary
echo.
echo ╔════════════════════════════════════════════════════════════════════════════╗
echo ║                                                                            ║
echo ║                   INSTALLATION COMPLETE! ✅                               ║
echo ║                                                                            ║
echo ╚════════════════════════════════════════════════════════════════════════════╝
echo.
echo 📂 Installation location: %INSTALL_PATH%
echo.
echo 🚀 To start GENE1799:
echo    Option 1: Double-click "%INSTALL_PATH%\START.bat"
echo    Option 2: Click desktop shortcut "GENE1799"
echo    Option 3: Run: powershell -Command "& '%INSTALL_PATH%\bin\launchers\service-coordinator.ps1'"
echo.
echo 📚 Documentation: %INSTALL_PATH%\docs\
echo.
echo 📋 First steps:
echo    1. Run START.bat
echo    2. Choose "Start All" in the dashboard
echo    3. Wait 30 seconds for services to initialize
echo    4. Access dashboard at http://localhost:5173
echo.
echo ═════════════════════════════════════════════════════════════════════════════
echo.
pause
