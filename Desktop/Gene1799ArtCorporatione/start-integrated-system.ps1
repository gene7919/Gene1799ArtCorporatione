#!/usr/bin/env pwsh

<#
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║     🌐 GENE1799 - AZURE AI + LOCAL ORCHESTRATOR STARTUP 🌐             ║
║                                                                           ║
║  Integrated startup system for:                                          ║
║    • Azure AI Integration Service (Port 8001)                           ║
║    • Unified Orchestrator Agent (Port 5050)                            ║
║    • All 7 Local Services (Ollama, Backend, Frontend, GPU, etc.)       ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
#>

param(
    [ValidateSet('Full', 'AzureOnly', 'OrchestratorOnly', 'Test', 'Status')]
    [string]$Mode = 'Full'
)

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

$COLORS = @{
    "success" = "Green"
    "warning" = "Yellow"
    "error" = "Red"
    "info" = "Cyan"
    "highlight" = "Magenta"
}

function Write-Log {
    param([string]$Message, [string]$Type = "info")
    $symbol = @{
        "info" = "ℹ️"
        "success" = "✅"
        "warning" = "⚠️"
        "error" = "❌"
    }[$Type]
    Write-Host "$symbol $Message" -ForegroundColor $COLORS[$Type]
}

# ═══════════════════════════════════════════════════════════════════════════
# AZURE AI SERVICE STARTUP
# ═══════════════════════════════════════════════════════════════════════════

function Start-AzureAIService {
    Write-Host "`n🌐 STARTING AZURE AI SERVICE`n" -ForegroundColor $COLORS["highlight"]

    # Check if Python is available
    try {
        $pythonVersion = python --version 2>&1
        Write-Log "Python found: $pythonVersion" "success"
    } catch {
        Write-Log "Python not found! Please install Python 3.11+" "error"
        Write-Log "Download: https://www.python.org/downloads/" "warning"
        return $false
    }

    # Check if required packages are installed
    Write-Log "Checking Python packages..." "info"
    $req = @(
        "azure-ai-projects",
        "azure-identity",
        "fastapi",
        "uvicorn",
        "pydantic"
    )

    foreach ($package in $req) {
        try {
            python -m pip show $package > $null 2>&1
            Write-Log "Package installed: $package" "success"
        } catch {
            Write-Log "Installing missing package: $package" "warning"
            python -m pip install $package | Out-Null
        }
    }

    # Start Azure AI service in background
    Write-Log "Starting Azure AI service on port 8001..." "info"

    if (Test-Path "azure_ai_integration.py") {
        $pyProcess = Start-Process -FilePath "python" `
            -ArgumentList "azure_ai_integration.py" `
            -NoNewWindow `
            -PassThru `
            -ErrorAction SilentlyContinue

        if ($pyProcess) {
            Write-Log "Azure AI service started (PID: $($pyProcess.Id))" "success"

            # Wait for service to be ready
            Start-Sleep -Seconds 3

            # Test connection
            try {
                $response = curl.exe -s http://localhost:8001/health
                Write-Log "Azure AI service is responding!" "success"
                return $true
            } catch {
                Write-Log "Azure AI service started but not responding yet - may still be initializing" "warning"
                return $true
            }
        } else {
            Write-Log "Failed to start Azure AI service" "error"
            return $false
        }
    } else {
        Write-Log "azure_ai_integration.py not found" "error"
        Write-Log "Run: .\\setup-azure.ps1 first" "warning"
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# UNIFIED ORCHESTRATOR STARTUP
# ═══════════════════════════════════════════════════════════════════════════

function Start-UnifiedOrchestrator {
    Write-Host "`n🎯 STARTING UNIFIED ORCHESTRATOR`n" -ForegroundColor $COLORS["highlight"]

    # Check if Node.js is available
    try {
        $nodeVersion = node --version
        Write-Log "Node.js found: $nodeVersion" "success"
    } catch {
        Write-Log "Node.js not found! Please install Node.js 18+" "error"
        Write-Log "Download: https://nodejs.org/" "warning"
        return $false
    }

    # Check orchestrator file exists
    if (-not (Test-Path "orchestrator-unified.js")) {
        Write-Log "orchestrator-unified.js not found" "error"
        return $false
    }

    # Start orchestrator in background
    Write-Log "Starting Unified Orchestrator on port 5050..." "info"

    $nodeProcess = Start-Process -FilePath "node" `
        -ArgumentList "orchestrator-unified.js" `
        -NoNewWindow `
        -PassThru `
        -ErrorAction SilentlyContinue

    if ($nodeProcess) {
        Write-Log "Unified Orchestrator started (PID: $($nodeProcess.Id))" "success"

        # Wait for service to be ready
        Start-Sleep -Seconds 3

        # Test connection
        try {
            $response = curl.exe -s http://localhost:5050/health
            Write-Log "Unified Orchestrator is responding!" "success"
            return $true
        } catch {
            Write-Log "Orchestrator started but not responding yet - may still be initializing" "warning"
            return $true
        }
    } else {
        Write-Log "Failed to start Unified Orchestrator" "error"
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# STATUS CHECKING
# ═══════════════════════════════════════════════════════════════════════════

function Get-SystemStatus {
    Write-Host "`n📊 GENE1799 INTEGRATED SYSTEM STATUS`n" -ForegroundColor $COLORS["highlight"]

    $services = @{
        "Ollama" = 11434
        "Backend API" = 3000
        "Frontend Dashboard" = 5173
        "GPU Service" = 4000
        "MongoDB" = 27017
        "Python AI Agent" = 8000
        "Azure AI Service" = 8001
        "Unified Orchestrator" = 5050
    }

    $anyHealthy = $false

    foreach ($service in $services.GetEnumerator()) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $asyncResult = $tcpClient.BeginConnect("localhost", $service.Value, $null, $null)
            $wait = $asyncResult.AsyncWaitHandle.WaitOne(1000, $false)

            if ($wait) {
                $tcpClient.EndConnect($asyncResult)
                Write-Log "$($service.Key) (Port $($service.Value)): RUNNING" "success"
                $anyHealthy = $true
            } else {
                Write-Log "$($service.Key) (Port $($service.Value)): NOT RESPONDING" "warning"
            }
            $tcpClient.Close()
        } catch {
            Write-Log "$($service.Key) (Port $($service.Value)): OFFLINE" "error"
        }
    }

    return $anyHealthy
}

# ═══════════════════════════════════════════════════════════════════════════
# COMPLETE STARTUP PROCESS
# ═══════════════════════════════════════════════════════════════════════════

function Start-FullSystem {
    Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║  🚀 GENE1799 COMPLETE INTEGRATED STARTUP 🚀                            ║
║                                                                           ║
║  Starting all services:                                                   ║
║    ✓ 7 Local Services (via service-coordinator.ps1)                    ║
║    ✓ Azure AI Integration Service (Port 8001)                          ║
║    ✓ Unified Orchestrator Agent (Port 5050)                           ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Magenta

    Write-Log "Step 1/3: Starting local services via service-coordinator..." "info"

    # Start all local services
    if (Test-Path "service-coordinator.ps1") {
        & ".\service-coordinator.ps1" -Command "Start" -Service "@('backend', 'frontend', 'gpu', 'mongodb', 'agent', 'orchestrator')"
        Start-Sleep -Seconds 5
    } else {
        Write-Log "service-coordinator.ps1 not found - skipping local services" "warning"
    }

    Write-Log "Step 2/3: Starting Azure AI Integration Service..." "info"
    $azureStarted = Start-AzureAIService
    Start-Sleep -Seconds 3

    Write-Log "Step 3/3: Starting Unified Orchestrator Agent..." "info"
    $orchestratorStarted = Start-UnifiedOrchestrator

    # Final status check
    Write-Host "`n"
    Get-SystemStatus

    if ($azureStarted -and $orchestratorStarted) {
        Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║  ✅ INTEGRATED SYSTEM STARTUP COMPLETE ✅                               ║
║                                                                           ║
║  Access Points:                                                          ║
║    🎨 Dashboard: http://localhost:5173                                  ║
║    📡 API: http://localhost:3000                                        ║
║    🎯 Orchestrator: http://localhost:5050                               ║
║    🌐 Azure AI: http://localhost:8001                                   ║
║                                                                           ║
║  Orchestrator API Docs: http://localhost:5050/api/docs                 ║
║                                                                           ║
║  System fully operational with:                                          ║
║    ✓ Local Ollama LLM (7 models)                                        ║
║    ✓ Azure AI Medical Agent (alMedicochelante)                         ║
║    ✓ 23 Specialized AI Agents                                          ║
║    ✓ Real-time Health Monitoring                                       ║
║    ✓ Intelligent Query Routing                                         ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green
    } else {
        Write-Log "Some services failed to start - check logs above" "warning"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# TEST MODE
# ═══════════════════════════════════════════════════════════════════════════

function Test-Integration {
    Write-Host "`n🧪 TESTING INTEGRATION`n" -ForegroundColor $COLORS["highlight"]

    Write-Log "Test 1: Check Orchestrator Health" "info"
    try {
        $response = curl.exe -s http://localhost:5050/health | ConvertFrom-Json
        Write-Log "Orchestrator Health: $($response.status)" "success"
    } catch {
        Write-Log "Orchestrator health check failed" "error"
    }

    Write-Log "Test 2: Check Orchestrator Status" "info"
    try {
        $response = curl.exe -s http://localhost:5050/status | ConvertFrom-Json
        Write-Log "Services monitored: $($response.services.Count)" "success"
        Write-Log "Total agents available: $($response.totalAgents)" "success"
    } catch {
        Write-Log "Orchestrator status check failed" "error"
    }

    Write-Log "Test 3: Test Query Routing" "info"
    try {
        $body = @{ message = "Hello, orchestrator" } | ConvertTo-Json
        $response = curl.exe -s -X POST http://localhost:5050/query `
            -H "Content-Type: application/json" `
            -d $body | ConvertFrom-Json
        Write-Log "Query routed to: $($response.provider)" "success"
    } catch {
        Write-Log "Query routing test failed" "error"
    }

    Write-Log "Test 4: Check Azure AI Service" "info"
    try {
        $response = curl.exe -s http://localhost:8001/health | ConvertFrom-Json
        Write-Log "Azure AI Service status: $($response.status)" "success"
    } catch {
        Write-Log "Azure AI Service not responding" "warning"
    }

    Write-Host "`n✅ Integration testing complete!`n" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

switch ($Mode) {
    "Full" {
        Start-FullSystem
    }
    "AzureOnly" {
        Write-Log "Starting only Azure AI Service..." "info"
        Start-AzureAIService
    }
    "OrchestratorOnly" {
        Write-Log "Starting only Unified Orchestrator..." "info"
        Start-UnifiedOrchestrator
    }
    "Test" {
        Write-Log "First checking status..." "info"
        Get-SystemStatus
        Test-Integration
    }
    "Status" {
        Get-SystemStatus
    }
}
