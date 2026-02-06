# gene1799_dashboard_integration.ps1
# Gene1799 Art Corporation - Dashboard Web Integration Script

param(
    [string]$Mode = "SETUP",
    [string]$DashboardPort = "8080"
)

# Configuration
$Config = @{
    DashboardRoot = "D:\Electronic\Dashboard"
    WebRoot = "D:\Electronic\Dashboard\Web"
    Database = "D:\Gene1799\Agents\agents_database.json"
    LogPath = "D:\Electronic\Dashboard\Logs"
    DashboardFile = "gene1799_dashboard.html"
}

# ═══════════════════════════════════════════════════════════
# LOGGING FUNCTION
# ═══════════════════════════════════════════════════════════

function Write-DashboardLog {
    param([string]$Message, [string]$Type = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $Config.LogPath "dashboard.log"
    
    $colors = @{
        "SUCCESS" = "Green"
        "ERROR" = "Red"
        "WARNING" = "Yellow"
        "INFO" = "Cyan"
        "DEBUG" = "Gray"
    }
    
    $color = $colors[$Type] ?? "White"
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
    
    # Salva nel log file
    "[$timestamp] [$Type] $Message" | Add-Content $logFile
}

# ═══════════════════════════════════════════════════════════
# SETUP
# ═══════════════════════════════════════════════════════════

function Initialize-Dashboard {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║     🎨 GENE1799 DASHBOARD INITIALIZATION 🎨              ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

    # Crea directory
    $dirs = @(
        $Config.DashboardRoot,
        $Config.WebRoot,
        $Config.LogPath,
        "D:\Electronic\Dashboard\Agents\Active",
        "D:\Electronic\Dashboard\Metrics",
        "D:\Electronic\Dashboard\Reports"
    )

    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-DashboardLog "Created directory: $dir" "SUCCESS"
        }
    }

    # Copia il file HTML del dashboard
    $dashboardFile = Join-Path (Get-Location) $Config.DashboardFile
    if (Test-Path $dashboardFile) {
        Copy-Item -Path $dashboardFile -Destination (Join-Path $Config.WebRoot "index.html") -Force
        Write-DashboardLog "Dashboard file deployed to web root" "SUCCESS"
    } else {
        Write-DashboardLog "Dashboard HTML file not found" "ERROR"
    }

    # Crea il file di configurazione del dashboard
    $dashboardConfig = @{
        name = "Gene1799 Art Corporation Neural Dashboard"
        version = "1.0"
        location = $Config.DashboardRoot
        webRoot = $Config.WebRoot
        port = $DashboardPort
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        active_agents = @()
        synaptic_connections = @{
            "D:\Electronic\Dashboard" = @("D:\Gene1799", "C:\AI")
        }
        modules = @(
            @{ name = "AgentManager"; status = "READY" }
            @{ name = "TrainingEngine"; status = "READY" }
            @{ name = "MetricsCollector"; status = "READY" }
            @{ name = "SynapticVisualizer"; status = "READY" }
        )
    }

    $configPath = Join-Path $Config.DashboardRoot "config.json"
    $dashboardConfig | ConvertTo-Json -Depth 10 | Set-Content $configPath
    Write-DashboardLog "Dashboard configuration created" "SUCCESS"

    Write-Host "`n✅ Dashboard initialized successfully!`n" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════
# SETUP AGENTS
# ═══════════════════════════════════════════════════════════

function Setup-DefaultAgents {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          📌 SETTING UP DEFAULT AGENTS 📌                 ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

    $agentConfigs = @(
        @{
            Name = "ArtAnalyzer"
            Type = "ART_CLASSIFIER"
            Description = "Analyzes and classifies artworks for Gene1799 Art Corporation"
            TrainingEpochs = 300
            Accuracy = 92.5
        }
        @{
            Name = "ArtworkManager"
            Type = "ASSET_MANAGER"
            Description = "Manages artwork inventory and metadata"
            TrainingEpochs = 200
            Accuracy = 88.3
        }
        @{
            Name = "QualityAssessor"
            Type = "QUALITY_EVALUATOR"
            Description = "Evaluates artwork quality and authenticity"
            TrainingEpochs = 250
            Accuracy = 78.9
        }
        @{
            Name = "CuratorAI"
            Type = "RECOMMENDATION_ENGINE"
            Description = "Provides curated recommendations for collectors"
            TrainingEpochs = 350
            Accuracy = 95.2
        }
    )

    foreach ($agentConfig in $agentConfigs) {
        Create-DashboardAgent -AgentConfig $agentConfig
    }

    Write-DashboardLog "All default agents created and configured" "SUCCESS"
}

function Create-DashboardAgent {
    param([hashtable]$AgentConfig)

    $agent = @{
        id = (New-Guid).ToString()
        name = $AgentConfig.Name
        type = $AgentConfig.Type
        description = $AgentConfig.Description
        created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        status = "ACTIVE"
        training_epochs = $AgentConfig.TrainingEpochs
        accuracy = $AgentConfig.Accuracy
        synaptic_layers = @(
            @{ layer_id = 1; neurons = 128; activation = "ReLU" }
            @{ layer_id = 2; neurons = 64; activation = "ReLU" }
            @{ layer_id = 3; neurons = 32; activation = "Sigmoid" }
        )
        connections = @{
            ai_core = "C:\AI\Agents\$($AgentConfig.Name)"
            gene1799 = "D:\Gene1799\Agents\$($AgentConfig.Name)"
            electronic = "D:\Electronic\Agents\$($AgentConfig.Name)"
            dashboard = "D:\Electronic\Dashboard\Agents\Active\$($AgentConfig.Name)"
        }
    }

    # Crea directory agent
    $agentDirs = @(
        "D:\Electronic\Dashboard\Agents\Active\$($AgentConfig.Name)"
        "D:\Gene1799\Agents\$($AgentConfig.Name)"
    )

    foreach ($dir in $agentDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }

    # Salva configurazione agent
    $agentConfigPath = "D:\Electronic\Dashboard\Agents\Active\$($AgentConfig.Name)\config.json"
    $agent | ConvertTo-Json -Depth 10 | Set-Content $agentConfigPath

    Write-DashboardLog "Agent '$($AgentConfig.Name)' created - Type: $($AgentConfig.Type) - Accuracy: $($AgentConfig.Accuracy)%" "SUCCESS"
}

# ═══════════════════════════════════════════════════════════
# METRICS COLLECTION
# ═══════════════════════════════════════════════════════════

function Collect-Metrics {
    Write-DashboardLog "Collecting system metrics..." "INFO"

    $agentsPath = "D:\Electronic\Dashboard\Agents\Active"
    $agents = @()
    
    if (Test-Path $agentsPath) {
        Get-ChildItem -Path $agentsPath -Directory | ForEach-Object {
            $configFile = Join-Path $_.FullName "config.json"
            if (Test-Path $configFile) {
                $agents += Get-Content $configFile | ConvertFrom-Json
            }
        }
    }

    $metrics = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        total_agents = $agents.Count
        active_agents = ($agents | Where-Object { $_.status -eq "ACTIVE" }).Count
        avg_accuracy = if ($agents.Count -gt 0) { 
            ($agents | Measure-Object -Property accuracy -Average).Average 
        } else { 
            0 
        }
        system_health = "OPERATIONAL"
        trained_agents = ($agents | Where-Object { $_.training_epochs -gt 0 }).Count
        agents = @($agents | Select-Object name, type, status, accuracy, training_epochs)
    }

    $metricsPath = Join-Path $Config.LogPath "metrics_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
    $metrics | ConvertTo-Json -Depth 10 | Set-Content $metricsPath

    Write-DashboardLog "Metrics collected: $($metrics.total_agents) agents, Avg Accuracy: $($metrics.avg_accuracy | ConvertTo-Json)%" "SUCCESS"
    
    return $metrics
}

# ═══════════════════════════════════════════════════════════
# WEB SERVER
# ═══════════════════════════════════════════════════════════

function Start-DashboardWebServer {
    param([int]$Port = 8080)

    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        🌐 STARTING DASHBOARD WEB SERVER 🌐               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    $indexPath = Join-Path $Config.WebRoot "index.html"
    
    if (-not (Test-Path $indexPath)) {
        Write-DashboardLog "Dashboard index.html not found at $indexPath" "ERROR"
        return
    }

    # Crea un semplice HTTP server in PowerShell
    $HttpListener = New-Object System.Net.HttpListener
    $HttpListener.Prefixes.Add("http://+:$Port/")
    
    try {
        $HttpListener.Start()
        Write-DashboardLog "Web server started on port $Port" "SUCCESS"
        Write-Host "✅ Dashboard available at: http://localhost:$Port`n" -ForegroundColor Green
        Write-Host "Press CTRL+C to stop the server...`n" -ForegroundColor Yellow

        while ($HttpListener.IsListening) {
            $Context = $HttpListener.GetContext()
            $Request = $Context.Request
            $Response = $Context.Response

            Write-DashboardLog "Request: $($Request.Url)" "INFO"

            # Serve il file HTML
            $Response.ContentType = "text/html; charset=utf-8"
            $Html = Get-Content -Path $indexPath -Raw
            $Buffer = [System.Text.Encoding]::UTF8.GetBytes($Html)
            $Response.ContentLength64 = $Buffer.Length
            $Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
            $Response.Close()
        }
    }
    catch {
        Write-DashboardLog "Error starting web server: $_" "ERROR"
    }
    finally {
        if ($HttpListener) {
            $HttpListener.Stop()
            $HttpListener.Dispose()
            Write-DashboardLog "Web server stopped" "INFO"
        }
    }
}

# ═══════════════════════════════════════════════════════════
# STATUS REPORT
# ═══════════════════════════════════════════════════════════

function Show-DashboardStatus {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       📊 DASHBOARD STATUS REPORT 📊                      ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    # Dashboard info
    Write-Host "🎨 Dashboard Configuration:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  Root Directory: $($Config.DashboardRoot)" -ForegroundColor Cyan
    Write-Host "  Web Root: $($Config.WebRoot)" -ForegroundColor Cyan
    Write-Host "  Port: $DashboardPort" -ForegroundColor Cyan

    # Agents info
    Write-Host "`n🤖 Registered Agents:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

    $agentsPath = "D:\Electronic\Dashboard\Agents\Active"
    if (Test-Path $agentsPath) {
        $agents = Get-ChildItem -Path $agentsPath -Directory
        
        if ($agents.Count -eq 0) {
            Write-Host "  No agents registered yet" -ForegroundColor Gray
        } else {
            foreach ($agent in $agents) {
                $configFile = Join-Path $agent.FullName "config.json"
                if (Test-Path $configFile) {
                    $agentData = Get-Content $configFile | ConvertFrom-Json
                    Write-Host "`n  📌 $($agentData.name)" -ForegroundColor Cyan
                    Write-Host "     Type: $($agentData.type)" -ForegroundColor Gray
                    Write-Host "     Status: $($agentData.status)" -ForegroundColor Green
                    Write-Host "     Accuracy: $($agentData.accuracy)%" -ForegroundColor Magenta
                    Write-Host "     Training Epochs: $($agentData.training_epochs)" -ForegroundColor Yellow
                }
            }
        }
    }

    # Metrics
    $metrics = Collect-Metrics
    Write-Host "`n📈 System Metrics:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  Total Agents: $($metrics.total_agents)" -ForegroundColor Cyan
    Write-Host "  Active Agents: $($metrics.active_agents)" -ForegroundColor Green
    Write-Host "  Average Accuracy: $([math]::Round($metrics.avg_accuracy, 2))%" -ForegroundColor Magenta
    Write-Host "  System Status: $($metrics.system_health)" -ForegroundColor Green

    Write-Host ""
}

# ═══════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════

Write-Host "`n🎨 GENE1799 NEURAL DASHBOARD v1.0" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

switch ($Mode) {
    "SETUP" {
        Initialize-Dashboard
        Setup-DefaultAgents
        Show-DashboardStatus
    }
    "WEB" {
        Start-DashboardWebServer -Port $DashboardPort
    }
    "STATUS" {
        Show-DashboardStatus
    }
    "METRICS" {
        Collect-Metrics
    }
    default {
        Write-Host "Usage: .\gene1799_dashboard_integration.ps1 -Mode <MODE>" -ForegroundColor Yellow
        Write-Host "`nAvailable modes:" -ForegroundColor Cyan
        Write-Host "  SETUP    - Initialize dashboard and create default agents" -ForegroundColor Gray
        Write-Host "  WEB      - Start the dashboard web server" -ForegroundColor Gray
        Write-Host "  STATUS   - Show dashboard status report" -ForegroundColor Gray
        Write-Host "  METRICS  - Collect and display system metrics" -ForegroundColor Gray
        Write-Host "`nExample:" -ForegroundColor Cyan
        Write-Host "  .\gene1799_dashboard_integration.ps1 -Mode SETUP" -ForegroundColor Gray
        Write-Host "  .\gene1799_dashboard_integration.ps1 -Mode WEB -DashboardPort 8080`n" -ForegroundColor Gray
    }
}
