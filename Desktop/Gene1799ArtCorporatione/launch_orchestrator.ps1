#!/usr/bin/env pwsh
<#
.SYNOPSIS
Gene1799 Orchestrator Launcher - PowerShell
Starts the master orchestrator for all services and AI agents

.DESCRIPTION
Launches the Gene1799 master orchestrator which manages:
- Backend API (Express.js)
- Frontend Web (React)
- AI Agent System (Python)
- Desktop App (Electron)
- AI Agents orchestration

.EXAMPLE
.\launch_orchestrator.ps1
#>

# Banner
Write-Host "`n" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "                                                        " -ForegroundColor Cyan
Write-Host "   GENE1799 MASTER ORCHESTRATOR                         " -ForegroundColor Cyan
Write-Host "   Service & Agent Orchestration System                 " -ForegroundColor Cyan
Write-Host "                                                        " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Check Python
Write-Host "[CHECK] Verifying environment..." -ForegroundColor Cyan
$pythonCheck = python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Python not found! Please install Python 3.9+" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Python: $pythonCheck" -ForegroundColor Green

# Check orchestrator file
if (!(Test-Path './orchestrator.py')) {
    Write-Host "[ERROR] orchestrator.py not found!" -ForegroundColor Red
    Write-Host "[INFO] Please run from Gene1799ArtCorporatione directory" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Orchestrator module found" -ForegroundColor Green

# Check dependencies
Write-Host "`n[CHECK] Verifying Python dependencies..." -ForegroundColor Cyan
$deps = @('asyncio', 'logging', 'json', 'enum')
foreach ($dep in $deps) {
    try {
        python -c "import $dep" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] $dep available" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[WARN] $dep (might need installation)" -ForegroundColor Yellow
    }
}

# Launch orchestrator
Write-Host "`n[INFO] Starting orchestrator..." -ForegroundColor Green
Write-Host "[INFO] Type 'help' for command list" -ForegroundColor Gray
Write-Host ""

python orchestrator.py

Write-Host "`n[OK] Orchestrator stopped" -ForegroundColor Green
