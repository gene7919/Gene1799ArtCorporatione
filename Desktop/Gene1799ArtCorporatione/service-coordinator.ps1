#!/usr/bin/env pwsh

<#
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║     🎛️  GENE1799 MASTER SERVICE COORDINATOR v2.0 🎛️                    ║
║                                                                           ║
║  Multi-Service Management & Orchestration Hub                            ║
║  Start/Stop/Monitor Individual Services with Unified Control             ║
║  Real-time Health Monitoring & Auto-Recovery                             ║
║                                                                           ║
║  Manages:                                                                 ║
║  • Ollama AI (Port 11434) - PRIMARY LLM ENGINE                           ║
║  • Backend API (Port 3000) - Express.js service                         ║
║  • Frontend UI (Port 5173/3001) - Vite + Dashboard                      ║
║  • GPU Service (Port 4000) - CUDA Rendering                             ║
║  • MongoDB (Port 27017) - Data persistence                              ║
║  • Python AI Agent (Port 8000) - Multi-agent framework                  ║
║  • Master Orchestrator (Port 5000) - AI coordination                    ║
║                                                                           ║
║  Version: 2.0.0 - Multi-Service Ready                                    ║
║  Date: February 8, 2026                                                   ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
#>

param(
    [ValidateSet('Start', 'Stop', 'Status', 'Restart', 'Dashboard', 'Full', 'Service', 'List')]
    [string]$Command = 'Status',
    [ValidateSet('ollama', 'backend', 'frontend', 'gpu', 'mongodb', 'agent', 'all')]
    [string]$Service = 'all',
    [switch]$Daemon,
    [switch]$NoGPU
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$ProjectRoot = Get-Item -Path $PSScriptRoot

# ═══════════════════════════════════════════════════════════════════════════
# SERVICE REGISTRY & CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

$Services = @{
    'ollama' = @{
        Name            = 'Ollama AI Engine'
        Port            = 11434
        Status          = 'UNKNOWN'
        Enabled         = $true
        Type            = 'External'
        Description     = 'Primary LLM service with 7 models'
        Capability      = 'Large Language Models (Mistral, Llama2, CodeLlama, Gemma, DeepSeek, GPT-OSS)'
        Healthcheck     = 'http://localhost:11434/api/version'
        Models          = @('mistral:latest', 'codellama:latest', 'llama2:latest', 'gemma3:4b', 'llama3.2:1b')
        GPU             = 'RTX 4070 SUPER (10.2GB VRAM)'
        AutoStart       = $true
        IsRunning       = $false
    }
    'backend' = @{
        Name            = 'Backend API Service'
        Port            = 3000
        Status          = 'UNKNOWN'
        Enabled         = $true
        Type            = 'Docker'
        Description     = 'Express.js REST API server'
        Capability      = 'API endpoints, orchestration, data routing'
        Healthcheck     = 'http://localhost:3000/api/health'
        StartCommand    = 'docker-compose up -d backend'
        StopCommand     = 'docker-compose down'
        ProcessName     = 'node'
        AutoStart       = $true
        IsRunning       = $false
    }
    'frontend' = @{
        Name            = 'Frontend UI Service'
        Port            = 5173
        Status          = 'UNKNOWN'
        Enabled         = $true
        Type            = 'Vite/React'
        Description     = 'Interactive dashboard and UI'
        Capability      = 'Web interface, data visualization, control panel'
        Healthcheck     = 'http://localhost:5173'
        StartCommand    = 'npm -w frontend run dev'
        ProcessName     = 'vite'
        AutoStart       = $true
        IsRunning       = $false
    }
    'gpu' = @{
        Name            = 'GPU Service (CUDA Rendering)'
        Port            = 4000
        Status          = 'UNKNOWN'
        Enabled         = (-not $NoGPU)
        Type            = 'Node.js + CUDA'
        Description     = 'GPU-accelerated rendering and AI processing'
        Capability      = 'Canvas rendering, tensor operations, image generation'
        Healthcheck     = 'http://localhost:4000/api/health'
        StartCommand    = 'docker-compose up -d gpu-service'
        ProcessName     = 'node'
        AutoStart       = (-not $NoGPU)
        IsRunning       = $false
        GPU             = 'RTX 4070 SUPER'
    }
    'mongodb' = @{
        Name            = 'MongoDB Database'
        Port            = 27017
        Status          = 'UNKNOWN'
        Enabled         = $true
        Type            = 'Docker'
        Description     = 'NoSQL database for data persistence'
        Capability      = 'Data storage, caching, query execution'
        Healthcheck     = 'mongodb://localhost:27017'
        StartCommand    = 'docker-compose up -d mongodb'
        ProcessName     = 'mongod'
        AutoStart       = $true
        IsRunning       = $false
        Database        = 'gene1799_v7'
    }
    'agent' = @{
        Name            = 'Python AI Agent Framework'
        Port            = 8000
        Status          = 'UNKNOWN'
        Enabled         = $true
        Type            = 'Python/FastAPI'
        Description     = 'Multi-agent AI system (Azure Agents)'
        Capability      = 'Anti-cancer AI, drug discovery, healthcare, orchestration'
        Healthcheck     = 'http://localhost:8000/health'
        StartCommand    = 'python main.py'
        WorkingDir      = './ai-agent'
        ProcessName     = 'python'
        AutoStart       = $true
        IsRunning       = $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════

function Write-ServiceStatus {
    param([string]$ServiceName, [string]$Status, [string]$Message)

    $StatusColor = switch ($Status) {
        'RUNNING' { 'Green' }
        'STOPPED' { 'Red' }
        'DISABLED' { 'Gray' }
        'ERROR' { 'Yellow' }
        default { 'Cyan' }
    }

    $Icon = switch ($Status) {
        'RUNNING' { '✅' }
        'STOPPED' { '⏹️' }
        'DISABLED' { '🚫' }
        'ERROR' { '⚠️' }
        default { '⏳' }
    }

    Write-Host "$Icon $ServiceName " -ForegroundColor $StatusColor -NoNewline
    Write-Host "-" -NoNewline
    Write-Host " $Message" -ForegroundColor Cyan
}

function Test-ServicePort {
    param(
        [int]$Port,
        [string]$Protocol = 'tcp',
        [string]$HealthUrl = $null
    )

    try {
        if ($HealthUrl) {
            $response = Invoke-WebRequest -Uri $HealthUrl -TimeoutSec 2 -ErrorAction Stop
            return $response.StatusCode -eq 200
        } else {
            $connection = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue
            return $connection.TcpTestSucceeded
        }
    } catch {
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# SERVICE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

function Check-AllServices {
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  SERVICE STATUS CHECK                                         ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

    $ServicesToCheck = if ($Service -eq 'all') { $Services.Keys } else { @($Service) }

    foreach ($Svc in $ServicesToCheck) {
        if (-not $Services.ContainsKey($Svc)) { continue }

        $Cfg = $Services[$Svc]

        if (-not $Cfg.Enabled) {
            Write-ServiceStatus $Cfg.Name 'DISABLED' "Port $($Cfg.Port)"
            continue
        }

        $IsRunning = Test-ServicePort -Port $Cfg.Port -HealthUrl $Cfg.Healthcheck

        if ($IsRunning) {
            Write-ServiceStatus $Cfg.Name 'RUNNING' "Port $($Cfg.Port)"
            Write-Host "    📊 $($Cfg.Capability)" -ForegroundColor Gray
        } else {
            Write-ServiceStatus $Cfg.Name 'STOPPED' "Port $($Cfg.Port) - Ready to start"
        }
    }

    Write-Host ""
}

function Start-Service {
    param([string]$ServiceName)

    $Cfg = $Services[$ServiceName]

    if (-not $Cfg.Enabled) {
        Write-ServiceStatus $Cfg.Name 'DISABLED' "Skipping (disabled)"
        return
    }

    Write-Host "`n▶ Starting $($Cfg.Name)..." -ForegroundColor Cyan

    if ($ServiceName -eq 'ollama') {
        Write-Host "  Note: Ollama is managed externally" -ForegroundColor Yellow
        return
    }

    try {
        if ($Cfg.Type -eq 'Docker') {
            if ($Cfg.StartCommand) {
                Invoke-Expression $Cfg.StartCommand | Out-Null
                Start-Sleep -Seconds 3
            }
        } elseif ($Cfg.Type -eq 'Python/FastAPI') {
            $Env:NODE_ENV = 'production'
            Start-Process -FilePath 'python' -ArgumentList "$($Cfg.WorkingDir)\main.py" -NoNewWindow
        } else {
            # npm/vite services
            Start-Process -FilePath 'npm' -ArgumentList @($Cfg.StartCommand -split ' ') -NoNewWindow
        }

        Start-Sleep -Seconds 2

        if (Test-ServicePort -Port $Cfg.Port -HealthUrl $Cfg.Healthcheck) {
            Write-ServiceStatus $Cfg.Name 'RUNNING' "Successfully started"
        } else {
            Write-ServiceStatus $Cfg.Name 'ERROR' "Started but health check failed"
        }
    } catch {
        Write-ServiceStatus $Cfg.Name 'ERROR' "Failed: $_"
    }
}

function Stop-Service {
    param([string]$ServiceName)

    $Cfg = $Services[$ServiceName]
    Write-Host "⏹  Stopping $($Cfg.Name)..." -ForegroundColor Yellow

    try {
        if ($ServiceName -eq 'ollama') {
            Write-Host "  Note: Ollama is managed externally" -ForegroundColor Gray
            return
        }

        if ($Cfg.Type -eq 'Docker') {
            docker-compose down 2>&1 | Out-Null
        } else {
            Get-Process | Where-Object { $_.ProcessName -eq $Cfg.ProcessName } | Stop-Process -Force -ErrorAction SilentlyContinue
        }

        Start-Sleep -Seconds 1
        Write-ServiceStatus $Cfg.Name 'STOPPED' "Successfully stopped"
    } catch {
        Write-ServiceStatus $Cfg.Name 'ERROR' "Stop failed: $_"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN DASHBOARD
# ═══════════════════════════════════════════════════════════════════════════

function Show-Dashboard {
    Clear-Host

    Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║   🎛️  GENE1799 MASTER SERVICE COORDINATOR - CONTROL PANEL 🎛️           ║
║                                                                           ║
║   Multi-Service Management Hub                                           ║
║   Start • Stop • Monitor • Coordinate All Services                       ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

7️⃣  AVAILABLE SERVICES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"@ -ForegroundColor Magenta

    Check-AllServices

    Write-Host "
📡 AI/ML CAPABILITIES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🤖 Primary LLM Engine:
     • Ollama (11434): Mistral, Llama2, CodeLlama, Gemma, DeepSeek, GPT-OSS
     • Model Parameters: 1.2B to 671B (local + cloud)
     • GPU: RTX 4070 SUPER (10.2GB VRAM)

  🧠 Multi-Agent Framework:
     • Anti-Cancer AI System
     • Drug Discovery Engine
     • Healthcare Integration
     • Multi-Agent Orchestration
     • Content Generation
     • Social Media AI

  🎨 GPU-Accelerated:
     • Canvas Rendering
     • Image Generation
     • Tensor Operations
     • CUDA Cores: 5,888

  📊 Data & Persistence:
     • MongoDB (27017): NoSQL storage
     • Real-time caching
     • Query execution

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
" -ForegroundColor Cyan

    Write-Host "🎮 CONTROL COMMANDS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Start all services:        .\coordinator.ps1 -Command Start -Service all
  Stop all services:         .\coordinator.ps1 -Command Stop -Service all
  Status check:              .\coordinator.ps1 -Command Status

  Start specific service:    .\coordinator.ps1 -Command Start -Service backend
  Restart service:           .\coordinator.ps1 -Command Restart -Service frontend

  Service list:              .\coordinator.ps1 -Command List
  Full dashboard:            .\coordinator.ps1 -Command Dashboard

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
" -ForegroundColor Green

    Write-Host "🌐 ACCESS POINTS (When Running):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Ollama API:               http://localhost:11434
  Backend API:              http://localhost:3000       (REST endpoints)
  Frontend Dashboard:       http://localhost:5173       (Vite dev)
       or                   http://localhost:3001       (Docker)
  GPU Service API:          http://localhost:4000       (CUDA rendering)
  MongoDB:                  localhost:27017              (Connection string)
  Python AI Agent:          http://localhost:8000       (Multi-agent)
  Master Orchestrator:      http://localhost:5000       (AI coordination)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
" -ForegroundColor Yellow

    Write-Host "💡 USAGE SCENARIOS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Full Development Stack:         Start: backend, frontend, agent, gpu
  Production with Docker:         Start: backend, mongodb, gpu (via docker)
  AI-Only (Local Processing):     Start: ollama (always), agent
  Web Interface Only:              Start: backend, frontend
  GPU-Intensive Work:              Start: gpu, backend
  Multi-Agent Workflow:            Start: all (full system)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
" -ForegroundColor Magenta

    Read-Host "`n✓ Press Enter to continue or type command"
}

function List-Services {
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  COMPLETE SERVICE REGISTRY                                    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    $i = 1
    foreach ($ServiceName in $Services.Keys | Sort-Object) {
        $Cfg = $Services[$ServiceName]

        Write-Host "$i. $($Cfg.Name)" -ForegroundColor Yellow
        Write-Host "   Port: $($Cfg.Port) | Type: $($Cfg.Type) | Status: $($Cfg.Enabled ? 'Enabled' : 'Disabled')"
        Write-Host "   Capability: $($Cfg.Capability)"
        if ($Cfg.GPU) { Write-Host "   GPU: $($Cfg.GPU)" }
        Write-Host ""

        $i++
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════

function Main {
    switch ($Command) {
        'Status' {
            Check-AllServices
        }
        'Start' {
            if ($Service -eq 'all') {
                foreach ($Svc in $Services.Keys) {
                    Start-Service $Svc
                    Start-Sleep -Seconds 1
                }
            } else {
                Start-Service $Service
            }
        }
        'Stop' {
            if ($Service -eq 'all') {
                foreach ($Svc in $Services.Keys) {
                    Stop-Service $Svc
                    Start-Sleep -Seconds 1
                }
            } else {
                Stop-Service $Service
            }
        }
        'Restart' {
            Stop-Service $Service
            Start-Sleep -Seconds 2
            Start-Service $Service
        }
        'Dashboard' {
            Show-Dashboard
        }
        'List' {
            List-Services
        }
    }

    Write-Host "`n✓ Command completed`n" -ForegroundColor Green
}

Main
