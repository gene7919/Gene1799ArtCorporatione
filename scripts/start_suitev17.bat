@echo off
cls
echo ========================================
echo  SUITEV17 PLATFORM LAUNCHER
echo ========================================
echo.

REM Check if Python is available
python --version > nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found in PATH
    exit /b 1
)

REM Check if Node.js is available
node --version > nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js not found in PATH
    exit /b 1
)

echo Starting SuiteV17 services...
echo.

REM Start Gateway (Node.js)
start "SuiteV17 Gateway" cmd /k "node gateway.js"
timeout /t 2 > nul

REM Start Social Server (Node.js)
start "SuiteV17 Social" cmd /k "node server.js"
timeout /t 2 > nul

REM Start Python API Server
start "SuiteV17 API" cmd /k "python api_server.py"
timeout /t 2 > nul

REM Start WebSocket Server
start "SuiteV17 WebSocket" cmd /k "python websocket_server.py"
timeout /t 2 > nul

REM Start Master Orchestrator
start "SuiteV17 Master" cmd /k "python suitev17_master.py"

echo.
echo ========================================
echo All services started!
echo ========================================
echo.
echo Services:
echo   - Gateway:      http://localhost:8080
echo   - Social API:   http://localhost:3007
echo   - REST API:     http://localhost:8083
echo   - WebSocket:    ws://localhost:8765
echo.
echo Press any key to stop all services...
pause > nul

REM Kill all Node.js processes
taskkill /F /FI "WINDOWTITLE eq SuiteV17*" 2> nul

echo.
echo All services stopped.
