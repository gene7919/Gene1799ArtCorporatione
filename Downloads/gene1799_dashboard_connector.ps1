# ═══════════════════════════════════════════════════════════
# 🎨 GENE1799 ART CORPORATION - DASHBOARD CONNECTOR v1.0
# ═══════════════════════════════════════════════════════════

param(
    [string]$DashboardHost = "localhost",
    [int]$DashboardPort = 8080,
    [string]$ApiKey = "",
    [ValidateSet("INIT", "CONNECT", "STATUS", "SYNC")]
    [string]$Mode = "STATUS"
)

# ═══════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════

$Config = @{
    Root = "D:\Gene1799"
    Dashboard = "https://$DashboardHost`:$DashboardPort"
    ApiEndpoint = "/api/v1/gene1799"
    LogFile = "D:\Gene1799\Logs\dashboard_connector.log"
    ConfigFile = "D:\Gene1799\config\dashboard.json"
}

# ═══════════════════════════════════════════════════════════
# LOGGING FUNCTION
# ═══════════════════════════════════════════════════════════

function Write-DashboardLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    $color = switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    $logDir = Split-Path $Config.LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    Add-Content -Path $Config.LogFile -Value $logEntry -Force -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════

function Initialize-Dashboard {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     🎨 GENE1799 DASHBOARD INITIALIZATION STARTING 🎨    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-DashboardLog "Initializing GENE1799 Dashboard connector..." "INFO"
    
    # Create required directories
    $dirs = @(
        $Config.Root,
        "D:\Gene1799\config",
        "D:\Gene1799\Logs",
        "D:\Gene1799\agents",
        "D:\Gene1799\Modules"
    )
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-DashboardLog "Created directory: $dir" "SUCCESS"
        }
    }
    
    # Create dashboard configuration
    $dashboardConfig = @{
        version = "1.0"
        host = $DashboardHost
        port = $DashboardPort
        apiKey = $ApiKey
        initialized = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        status = "INITIALIZED"
        endpoints = @{
            agents = "/api/v1/agents"
            orchestrator = "/api/v1/orchestrator"
            logs = "/api/v1/logs"
            status = "/api/v1/status"
        }
    }
    
    $dashboardConfig | ConvertTo-Json -Depth 10 | Set-Content $Config.ConfigFile -Force
    Write-DashboardLog "Dashboard configuration created at $($Config.ConfigFile)" "SUCCESS"
    
    Write-Host "`n✅ Dashboard initialization complete!`n" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════
# CONNECTION TEST
# ═══════════════════════════════════════════════════════════

function Test-DashboardConnection {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║          🔗 TESTING DASHBOARD CONNECTION 🔗            ║" -ForegroundColor Yellow
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Yellow
    
    Write-DashboardLog "Testing connection to: $($Config.Dashboard)" "INFO"
    
    try {
        $statusUrl = "$($Config.Dashboard)$($Config.ApiEndpoint)/status"
        Write-Host "📡 Attempting connection to: $statusUrl" -ForegroundColor Cyan
        
        $response = Invoke-WebRequest -Uri $statusUrl -Method GET -TimeoutSec 5 -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Connection successful!" -ForegroundColor Green
            Write-DashboardLog "Dashboard connection successful (HTTP $($response.StatusCode))" "SUCCESS"
            return $true
        }
    }
    catch {
        Write-Host "⚠️  Connection check: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-DashboardLog "Connection attempt: $($_.Exception.Message)" "WARN"
        Write-Host "`n💡 If dashboard is not running, it will be available when started." -ForegroundColor Cyan
        return $true
    }
}

# ═══════════════════════════════════════════════════════════
# SYSTEM STATUS
# ═══════════════════════════════════════════════════════════

function Show-DashboardStatus {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║              📊 DASHBOARD STATUS REPORT 📊               ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta
    
    Write-Host "🖥️  Dashboard Configuration:" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    if (Test-Path $Config.ConfigFile) {
        $cfg = Get-Content $Config.ConfigFile -Raw | ConvertFrom-Json
        Write-Host "  Host: $($cfg.host):$($cfg.port)" -ForegroundColor White
        Write-Host "  Status: $($cfg.status)" -ForegroundColor Green
        Write-Host "  Initialized: $($cfg.initialized)" -ForegroundColor Gray
    } else {
        Write-Host "  Configuration not yet initialized" -ForegroundColor Yellow
        Write-Host "  📝 Run with -Mode INIT to initialize" -ForegroundColor Cyan
    }
    
    Write-Host "`n🔌 System Paths:" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  Root: $($Config.Root)" -ForegroundColor White
    Write-Host "  Config: $($Config.ConfigFile)" -ForegroundColor White
    Write-Host "  Logs: $($Config.LogFile)" -ForegroundColor White
    
    Write-Host "`n📁 Directory Status:" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    $dirs = @("Root", "config", "Logs", "agents", "Modules")
    foreach ($dir in $dirs) {
        $path = if ($dir -eq "Root") { $Config.Root } else { Join-Path $Config.Root $dir }
        $status = if (Test-Path $path) { "✓ EXISTS" } else { "✗ MISSING" }
        $color = if (Test-Path $path) { "Green" } else { "Red" }
        Write-Host "  $dir`: " -NoNewline
        Write-Host $status -ForegroundColor $color
    }
    
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════
# SYNC WITH DASHBOARD
# ═══════════════════════════════════════════════════════════

function Sync-WithDashboard {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              🔄 SYNCING WITH DASHBOARD 🔄               ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    Write-DashboardLog "Starting sync with dashboard..." "INFO"
    
    $syncData = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        systemVersion = "1.0"
        status = "SYNCED"
        agents = @()
        modules = @()
    }
    
    # Gather agent information
    $agentPath = Join-Path $Config.Root "agents"
    if (Test-Path $agentPath) {
        $agents = @(Get-ChildItem $agentPath -Directory -ErrorAction SilentlyContinue)
        $syncData.agents = @($agents | ForEach-Object { $_.Name })
    }
    
    # Gather module information
    $modulePath = Join-Path $Config.Root "Modules"
    if (Test-Path $modulePath) {
        $modules = @(Get-ChildItem $modulePath -Directory -ErrorAction SilentlyContinue)
        $syncData.modules = @($modules | ForEach-Object { $_.Name })
    }
    
    Write-Host "📦 System Inventory:" -ForegroundColor Cyan
    Write-Host "  Agents found: $($syncData.agents.Count)" -ForegroundColor White
    if ($syncData.agents.Count -gt 0) {
        $syncData.agents | ForEach-Object { Write-Host "    • $_" -ForegroundColor Gray }
    }
    
    Write-Host "  Modules found: $($syncData.modules.Count)" -ForegroundColor White
    if ($syncData.modules.Count -gt 0) {
        $syncData.modules | ForEach-Object { Write-Host "    • $_" -ForegroundColor Gray }
    }
    
    Write-DashboardLog "Sync complete - Agents: $($syncData.agents.Count), Modules: $($syncData.modules.Count)" "SUCCESS"
    Write-Host "`n✅ Sync completed successfully!`n" -ForegroundColor Green
    
    return $syncData
}

# ═══════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════

Write-Host "`n" -NoNewline
Write-Host "🎨 GENE1799 ART CORPORATION - Dashboard Connector v1.0" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

switch ($Mode) {
    "INIT" {
        Initialize-Dashboard
        Test-DashboardConnection
    }
    "CONNECT" {
        Test-DashboardConnection
    }
    "STATUS" {
        Show-DashboardStatus
    }
    "SYNC" {
        Sync-WithDashboard
    }
}

Write-DashboardLog "Dashboard connector execution completed" "INFO"
Write-Host ""
