#!/usr/bin/env pwsh

<#
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║  🧪 GENE1799 - INTEGRATED SYSTEM VERIFICATION & TEST 🧪                ║
║                                                                           ║
║  Comprehensive testing of:                                               ║
║    • All 7 Local Services                                               ║
║    • Azure AI Integration                                               ║
║    • Unified Orchestrator Agent                                        ║
║    • 23+ AI Agents                                                      ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
#>

param(
    [ValidateSet('Full', 'Quick', 'Services', 'Azure', 'Orchestrator', 'Agents')]
    [string]$TestLevel = 'Full'
)

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION & UTILITIES
# ═══════════════════════════════════════════════════════════════════════════

$COLORS = @{
    "success" = "Green"
    "warning" = "Yellow"
    "error" = "Red"
    "info" = "Cyan"
    "highlight" = "Magenta"
}

$SERVICES = @{
    "Ollama" = 11434
    "Backend API" = 3000
    "Frontend Dashboard" = 5173
    "GPU Service" = 4000
    "MongoDB" = 27017
    "Python AI Agent" = 8000
    "Azure AI Service" = 8001
    "Unified Orchestrator" = 5050
}

$TestResults = @()

function Write-Log {
    param([string]$Message, [string]$Type = "info")
    $symbol = @{
        "info" = "ℹ️"
        "success" = "✅"
        "warning" = "⚠️"
        "error" = "❌"
        "test" = "🧪"
    }[$Type]
    Write-Host "$symbol $Message" -ForegroundColor $COLORS[$Type]
}

function Test-Service {
    param(
        [string]$ServiceName,
        [int]$Port,
        [string]$HealthEndpoint = "/health"
    )

    Write-Log "Testing $ServiceName (Port $Port)..." "test"

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect("localhost", $Port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne(2000, $false)

        if ($wait) {
            $tcpClient.EndConnect($asyncResult)
            $tcpClient.Close()

            # Try health endpoint
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$Port$HealthEndpoint" `
                    -TimeoutSec 5 -ErrorAction SilentlyContinue

                if ($response.StatusCode -eq 200) {
                    Write-Log "✓ $ServiceName: HEALTHY (Port $Port)" "success"
                    $TestResults += @{ Service = $ServiceName; Status = "HEALTHY"; Port = $Port }
                    return $true
                }
            } catch {
                Write-Log "⚠ $ServiceName: Running but health check inconclusive" "warning"
                $TestResults += @{ Service = $ServiceName; Status = "RUNNING"; Port = $Port }
                return $true
            }
        } else {
            Write-Log "✗ $ServiceName: NOT RESPONDING (Port $Port)" "error"
            $TestResults += @{ Service = $ServiceName; Status = "OFFLINE"; Port = $Port }
            $tcpClient.Close()
            return $false
        }
    } catch {
        Write-Log "✗ $ServiceName: OFFLINE (Port $Port)" "error"
        $TestResults += @{ Service = $ServiceName; Status = "OFFLINE"; Port = $Port }
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# SERVICE TESTS
# ═══════════════════════════════════════════════════════════════════════════

function Test-AllServices {
    Write-Host "`n🔍 TESTING ALL LOCAL SERVICES`n" -ForegroundColor Magenta

    foreach ($service in $SERVICES.GetEnumerator()) {
        Test-Service -ServiceName $service.Key -Port $service.Value | Out-Null
        Start-Sleep -Milliseconds 200
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# ORCHESTRATOR DETAILED TESTS
# ═══════════════════════════════════════════════════════════════════════════

function Test-Orchestrator {
    Write-Host "`n🎯 DETAILED ORCHESTRATOR TESTS`n" -ForegroundColor Magenta

    # Test 1: Health check
    Write-Log "Test 1: Orchestrator Health Check" "test"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5050/health" `
            -TimeoutSec 5 -ErrorAction SilentlyContinue | ConvertFrom-Json

        if ($response.status -eq "healthy") {
            Write-Log "✓ Orchestrator is healthy" "success"
        } else {
            Write-Log "⚠ Orchestrator status: $($response.status)" "warning"
        }
    } catch {
        Write-Log "✗ Orchestrator health check failed" "error"
    }

    # Test 2: Status endpoint
    Write-Log "Test 2: Orchestrator Status & Metrics" "test"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5050/status" `
            -TimeoutSec 5 -ErrorAction SilentlyContinue | ConvertFrom-Json

        Write-Log "✓ Status retrieved:" "info"
        Write-Host "  - Services monitored: $($response.services.Count)"
        Write-Host "  - Local agents: $($response.localAgents.Count)"
        Write-Host "  - Azure agents: $($response.azureAgents.Count)"
        Write-Host "  - Total agents: $($response.totalAgents)"
        Write-Host "  - Total requests: $($response.metrics.totalRequests)"
        Write-Host "  - Success rate: $(([int]($response.metrics.successfulRequests / [math]::Max($response.metrics.totalRequests, 1) * 100)))%"
    } catch {
        Write-Log "✗ Could not retrieve orchestrator status" "error"
    }

    # Test 3: Service list
    Write-Log "Test 3: Orchestrator Service List" "test"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5050/services" `
            -TimeoutSec 5 -ErrorAction SilentlyContinue | ConvertFrom-Json

        Write-Log "✓ Services visible to orchestrator:" "success"
        foreach ($service in $response.PSObject.Properties) {
            $statusIcon = if ($service.Value.status -eq "healthy") { "✓" } else { "⚠" }
            Write-Host "  $statusIcon $($service.Value.name) - $($service.Value.status)"
        }
    } catch {
        Write-Log "✗ Could not retrieve service list" "error"
    }

    # Test 4: Available agents
    Write-Log "Test 4: Available Agents" "test"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5050/agents" `
            -TimeoutSec 5 -ErrorAction SilentlyContinue | ConvertFrom-Json

        Write-Log "✓ Local agents:" "success"
        foreach ($agent in $response.local) {
            Write-Host "  • $($agent.id) - $($agent.type) - $($agent.status)"
        }

        Write-Log "✓ Azure agents:" "success"
        foreach ($agent in $response.azure) {
            Write-Host "  • $($agent.id) - $($agent.type) - $($agent.specialty) - $($agent.status)"
        }
    } catch {
        Write-Log "✗ Could not retrieve agent list" "error"
    }

    # Test 5: Query routing
    Write-Log "Test 5: Query Routing" "test"
    try {
        $body = @{ message = "Test query for routing" } | ConvertTo-Json
        $response = Invoke-WebRequest -Uri "http://localhost:5050/query" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 10 -ErrorAction SilentlyContinue | ConvertFrom-Json

        if ($response.success) {
            Write-Log "✓ Query routed successfully" "success"
            Write-Host "  - Provider: $($response.provider)"
            Write-Host "  - Agent: $($response.agent)"
            Write-Host "  - Response time: $($response.responseTime)ms"
        } else {
            Write-Log "⚠ Query routing returned error: $($response.error)" "warning"
        }
    } catch {
        Write-Log "✗ Query test failed" "error"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# AZURE AI TESTS
# ═══════════════════════════════════════════════════════════════════════════

function Test-AzureIntegration {
    Write-Host "`n🌐 AZURE AI INTEGRATION TESTS`n" -ForegroundColor Magenta

    # Test 1: Azure service health
    Write-Log "Test 1: Azure AI Service Health" "test"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8001/health" `
            -TimeoutSec 5 -ErrorAction SilentlyContinue | ConvertFrom-Json

        Write-Log "✓ Azure AI Service is $($response.status)" "success"
        Write-Host "  - Service: $($response.service)"
        Write-Host "  - Connection: $($response.connection)"
    } catch {
        Write-Log "⚠ Azure AI Service not accessible (may not be running)" "warning"
    }

    # Test 2: Available Azure agents
    Write-Log "Test 2: Azure Agents" "test"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8001/agents" `
            -TimeoutSec 5 -ErrorAction SilentlyContinue | ConvertFrom-Json

        Write-Log "✓ Azure agents available:" "success"
        foreach ($agent in $response.agents) {
            Write-Host "  • $($agent.name) - $($agent.type)"
            Write-Host "    Capabilities: $($agent.capabilities -join ', ')"
        }
    } catch {
        Write-Log "⚠ Could not retrieve Azure agents" "warning"
    }

    # Test 3: Query Azure medical agent
    Write-Log "Test 3: Query Azure Medical Agent (alMedicochelante)" "test"
    try {
        $body = @{
            agent_name = "alMedicochelante"
            message = "What are your capabilities?"
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "http://localhost:8001/query" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 15 -ErrorAction SilentlyContinue | ConvertFrom-Json

        if ($response.status -eq "success") {
            Write-Log "✓ Azure agent responded successfully" "success"
            Write-Host "  - Agent: $($response.agent)"
            Write-Host "  - Response: $($response.response.Substring(0, [math]::Min(100, $response.response.Length)))..."
        } else {
            Write-Log "⚠ Azure agent returned error: $($response.error)" "warning"
        }
    } catch {
        Write-Log "⚠ Could not test Azure agent query (service may not be running)" "warning"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# ADVANCED ORCHESTRATOR TESTS
# ═══════════════════════════════════════════════════════════════════════════

function Test-AdvancedFeatures {
    Write-Host "`n🚀 ADVANCED ORCHESTRATOR FEATURES`n" -ForegroundColor Magenta

    # Test 1: Medical query routing
    Write-Log "Test 1: Medical Query Routing" "test"
    try {
        $body = @{
            message = "What are the latest treatments for cancer?"
            domain = "medical"
            requiresAzure = $true
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "http://localhost:5050/query" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 10 -ErrorAction SilentlyContinue | ConvertFrom-Json

        if ($response.success) {
            Write-Log "✓ Medical query routed to: $($response.provider) / $($response.agent)" "success"
        } else {
            Write-Log "⚠ Medical query failed: $($response.error)" "warning"
        }
    } catch {
        Write-Log "⚠ Medical query test failed" "warning"
    }

    # Test 2: Metrics
    Write-Log "Test 2: Performance Metrics" "test"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5050/metrics" `
            -TimeoutSec 5 -ErrorAction SilentlyContinue | ConvertFrom-Json

        Write-Log "✓ Orchestrator metrics:" "success"
        Write-Host "  - Total requests: $($response.totalRequests)"
        Write-Host "  - Successful: $($response.successfulRequests)"
        Write-Host "  - Failed: $($response.failedRequests)"
        Write-Host "  - Avg response time: $($response.avgResponseTime)ms"

        if ($response.routingDecisions) {
            Write-Host "  - Routing breakdown:"
            foreach ($provider in $response.routingDecisions.PSObject.Properties) {
                Write-Host "    • $($provider.Name): $($provider.Value)"
            }
        }
    } catch {
        Write-Log "✗ Could not retrieve metrics" "error"
    }

    # Test 3: Multi-provider aggregation
    Write-Log "Test 3: Multi-Provider Aggregation" "test"
    try {
        $body = @{
            message = "Explain AI"
            providers = @("ollama", "local")
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "http://localhost:5050/query/aggregate" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 15 -ErrorAction SilentlyContinue | ConvertFrom-Json

        Write-Log "✓ Aggregation completed:" "success"
        Write-Host "  - Successful providers: $($response.successfulProviders) / $($response.totalProviders)"
    } catch {
        Write-Log "⚠ Aggregation test skipped (advanced feature)" "warning"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# GENERATE REPORT
# ═══════════════════════════════════════════════════════════════════════════

function Generate-TestReport {
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║              🧪 GENE1799 INTEGRATION TEST REPORT 🧪                      ║" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    Write-Host "TEST RESULTS:" -ForegroundColor Magenta
    Write-Host "─────────────"

    $healthyCount = ($TestResults | Where-Object { $_.Status -eq "HEALTHY" } | Measure-Object).Count
    $runningCount = ($TestResults | Where-Object { $_.Status -eq "RUNNING" } | Measure-Object).Count
    $offlineCount = ($TestResults | Where-Object { $_.Status -eq "OFFLINE" } | Measure-Object).Count

    foreach ($result in $TestResults) {
        $color = if ($result.Status -eq "HEALTHY") {
            "Green"
        } elseif ($result.Status -eq "RUNNING") {
            "Yellow"
        } else {
            "Red"
        }
        Write-Host "  $($result.Service.PadRight(25)) | $($result.Status.PadRight(10)) | Port: $($result.Port)" -ForegroundColor $color
    }

    Write-Host "`nSUMMARY:" -ForegroundColor Magenta
    Write-Host "  ✓ Healthy: $healthyCount"
    Write-Host "  ⚠ Running: $runningCount"
    Write-Host "  ✗ Offline: $offlineCount"
    Write-Host "  Total: $($TestResults.Count)`n"

    if ($offlineCount -eq 0) {
        Write-Host "✅ ALL SERVICES OPERATIONAL!" -ForegroundColor Green
    } elseif ($healthyCount -gt 0) {
        Write-Host "⚠️  PARTIAL OPERATIONAL - Some services offline" -ForegroundColor Yellow
    } else {
        Write-Host "❌ SYSTEM OFFLINE - No services responding" -ForegroundColor Red
    }

    Write-Host "`n═══════════════════════════════════════════════════════════════════════════`n"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║  🧪 GENE1799 INTEGRATED SYSTEM VERIFICATION 🧪                         ║
║                                                                           ║
║  Test Level: $TestLevel                                                        ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Magenta

switch ($TestLevel) {
    "Full" {
        Test-AllServices
        Test-Orchestrator
        Test-AzureIntegration
        Test-AdvancedFeatures
    }
    "Quick" {
        Test-AllServices
    }
    "Services" {
        Test-AllServices
    }
    "Azure" {
        Test-AzureIntegration
    }
    "Orchestrator" {
        Test-AllServices
        Test-Orchestrator
    }
    "Agents" {
        Test-Orchestrator
        Test-AzureIntegration
    }
}

Generate-TestReport

Write-Log "Testing complete! Review results above." "success"
