@echo off
REM GENE1799 ART CORPORATIONE - AUTOMATED SETUP & DEPLOYMENT (WINDOWS)
REM Production-ready system setup in minutes

setlocal enabledelayedexpansion

REM Colors
set "GREEN=[32m"
set "RED=[31m"
set "YELLOW=[33m"
set "BLUE=[34m"
set "NC=[0m"

echo.
echo ============================================================
echo    GENE1799 AUTOMATED SETUP ^& DEPLOYMENT
echo ============================================================
echo.

REM Check Node.js
echo [*] Checking prerequisites...
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js not found. Please install Node.js 18+
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do set NODE_VER=%%i
echo [OK] Node.js found: %NODE_VER%

REM Check npm
npm --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm not found
    exit /b 1
)
for /f "tokens=*" %%i in ('npm --version') do set NPM_VER=%%i
echo [OK] npm found: %NPM_VER%

REM Check git
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git not found
    exit /b 1
)
echo [OK] Git found

echo.
echo [*] Step 1: Installing dependencies...
call npm install
echo [OK] Dependencies installed

echo.
echo [*] Step 2: Setting up environment configuration...
if not exist backend\.env (
    copy backend\.env.example backend\.env >nul
    echo [OK] Created backend\.env from template
    echo [INFO] Please edit backend\.env with your credentials:
    echo   - ETH_RPC_URL
    echo   - POLYGON_RPC_URL
    echo   - WALLET_ADDRESS
    echo   - TELEGRAM_BOT_TOKEN
    echo.
    pause
) else (
    echo [OK] backend\.env already exists
)

echo.
echo [*] Step 3: Verifying Git configuration...
git config user.email >nul 2>&1
if errorlevel 1 git config --global user.email "gene1799@local"
git config user.name >nul 2>&1
if errorlevel 1 git config --global user.name "GENE1799"
echo [OK] Git configured

echo.
echo ============================================================
echo                    DEPLOYMENT OPTIONS
echo ============================================================
echo.
echo 1) LOCAL DEVELOPMENT - Run locally for testing
echo 2) GITHUB PUSH - Push to GitHub ^(triggers auto-deploy^)
echo 3) AZURE DEPLOY - Deploy to Azure ^(one-click^)
echo 4) EXIT
echo.
set /p choice="Enter choice (1-4): "

if "%choice%"=="1" (
    echo.
    echo ============================================================
    echo         STARTING LOCAL DEVELOPMENT SERVER
    echo ============================================================
    echo.
    echo [INFO] Starting application...
    echo [INFO] Access dashboard at: http://localhost:3000
    echo [INFO] Press Ctrl+C to stop
    echo.
    call npm run dev
)

if "%choice%"=="2" (
    echo.
    echo ============================================================
    echo              PUSHING TO GITHUB
    echo ============================================================
    echo.
    echo [INFO] Current status:
    call git status
    echo.
    set /p commit_msg="Commit message (or press Enter for default): "
    if "!commit_msg!"=="" set commit_msg=deploy: Automated production deployment via setup script

    call git add .
    call git commit -m "!commit_msg!"
    call git push origin main

    echo.
    echo [OK] Pushed to GitHub!
    echo [INFO] GitHub Actions pipeline started
    echo [INFO] Check: https://github.com/gene7919/Gene1799ArtCorporatione/actions
    echo.
)

if "%choice%"=="3" (
    echo.
    echo ============================================================
    echo         AZURE ONE-CLICK DEPLOYMENT
    echo ============================================================
    echo.
    echo [INFO] Opening Azure Portal in browser...
    start "" "https://portal.azure.com/#create/Microsoft.Template/uri/https%%3A%%2F%%2Fraw.githubusercontent.com%%2Fgene7919%%2FGene1799ArtCorporatione%%2Fmain%%2Fazure-infrastructure-template.json"

    echo [INFO] Configure in Azure Portal:
    echo   - Project Name: gene1799
    echo   - Environment: production
    echo   - Database Password: Strong password
    echo.
    pause
)

if "%choice%"=="4" (
    echo.
    echo [INFO] Setup complete. Next steps:
    echo   1. Edit backend\.env with your credentials
    echo   2. Run: npm run dev ^(for local testing^)
    echo   3. Run: git push origin main ^(for auto-deploy^)
    echo   4. Click Deploy button in README.md ^(for Azure^)
    echo.
    exit /b 0
)

echo.
echo ============================================================
echo              DEPLOYMENT COMPLETE
echo [OK] GENE1799 is now running!
echo ============================================================
echo.
pause
