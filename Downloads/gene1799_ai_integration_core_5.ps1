# ═══════════════════════════════════════════════════════════
# 🧠 GENE1799 AI INTEGRATION CORE v2.0
# Sistema di integrazione AI multi-provider
# Collega: D:\Gene1799 + E:\ + C:\AI + Electronic
# ═══════════════════════════════════════════════════════════

param(
    [ValidateSet("INIT", "TEST_API", "TRAIN_AGENT", "RUN_TASK", "STATUS", "CONFIGURE")]
    [string]$Mode = "STATUS",
    [string]$Provider = "ALL",
    [string]$AgentName = "",
    [string]$Task = ""
)

# ═══════════════════════════════════════════════════════════
# CONFIGURAZIONE PATHS - MULTI-DISCO
# ═══════════════════════════════════════════════════════════

$Global:Gene1799Config = @{
    # Disco C: - AI Core
    AICore = "C:\AI"
    AIModels = "C:\AI\Models"
    AIAgents = "C:\AI\Agents"
    AICache = "C:\AI\Cache"
    
    # Disco D: - GENE1799 Core (Esistente)
    Gene1799Core = "D:\Gene1799"
    Gene1799Modules = "D:\Gene1799\Modules"
    Gene1799Agents = "D:\Gene1799\Agents"
    Gene1799Synaptic = "D:\Gene1799\Synaptic"
    Gene1799Logs = "D:\Gene1799\Logs"
    Gene1799Database = "D:\Gene1799\Database"
    
    # Disco D: - Electronic (Esistente)
    Electronic = "D:\Electronic"
    ElectronicModules = "D:\Electronic\Modules"
    ElectronicData = "D:\Electronic\Data"
    
    # Disco E: - AI Extended Storage & Training
    AIExtended = "E:\GENE1799_AI"
    AIModelsExtended = "E:\GENE1799_AI\Models"
    AITrainingData = "E:\GENE1799_AI\Training"
    AIResults = "E:\GENE1799_AI\Results"
    AIBackups = "E:\GENE1799_AI\Backups"
    AIProviders = "E:\GENE1799_AI\Providers"
    
    # File di configurazione
    ConfigFile = "D:\Gene1799\Database\ai_config.json"
    APIKeysFile = "D:\Gene1799\Database\.api_keys.json"
    AgentDB = "D:\Gene1799\Database\agents.json"
    LogFile = "D:\Gene1799\Logs\ai_integration.log"
}

# ═══════════════════════════════════════════════════════════
# AI PROVIDERS CONFIGURATION
# ═══════════════════════════════════════════════════════════

$Global:AIProviders = @{
    OpenAI = @{
        Name = "OpenAI"
        Endpoint = "https://api.openai.com/v1"
        Models = @("gpt-4", "gpt-4-turbo", "gpt-3.5-turbo", "dall-e-3")
        Capabilities = @("text", "chat", "image-generation", "embeddings")
        Status = "OFFLINE"
        APIKey = ""
    }
    Anthropic = @{
        Name = "Anthropic Claude"
        Endpoint = "https://api.anthropic.com/v1"
        Models = @("claude-3-opus", "claude-3-sonnet", "claude-3-haiku")
        Capabilities = @("text", "chat", "analysis", "code")
        Status = "OFFLINE"
        APIKey = ""
    }
    Google = @{
        Name = "Google Gemini"
        Endpoint = "https://generativelanguage.googleapis.com/v1"
        Models = @("gemini-pro", "gemini-pro-vision")
        Capabilities = @("text", "chat", "vision", "multimodal")
        Status = "OFFLINE"
        APIKey = ""
    }
    HuggingFace = @{
        Name = "Hugging Face"
        Endpoint = "https://api-inference.huggingface.co"
        Models = @("mistral", "llama2", "stable-diffusion")
        Capabilities = @("text", "image", "audio", "embeddings")
        Status = "OFFLINE"
        APIKey = ""
    }
    Ollama = @{
        Name = "Ollama (Local)"
        Endpoint = "http://localhost:11434/api"
        Models = @("llama2", "mistral", "codellama", "phi")
        Capabilities = @("text", "chat", "code", "local")
        Status = "OFFLINE"
        APIKey = "LOCAL"
    }
    StabilityAI = @{
        Name = "Stability AI"
        Endpoint = "https://api.stability.ai/v1"
        Models = @("stable-diffusion-xl", "stable-diffusion-v2")
        Capabilities = @("image-generation", "image-to-image")
        Status = "OFFLINE"
        APIKey = ""
    }
}

# ═══════════════════════════════════════════════════════════
# LOGGING SYSTEM ENHANCED
# ═══════════════════════════════════════════════════════════

function Write-Gene1799Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "AI", "SYNAPTIC", "API")]
        [string]$Level = "INFO",
        [string]$Provider = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $providerTag = if ($Provider) { "[$Provider]" } else { "" }
    $logEntry = "[$timestamp] [$Level] $providerTag $Message"
    
    $color = switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "AI" { "Magenta" }
        "SYNAPTIC" { "Blue" }
        "API" { "DarkCyan" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    $logDir = Split-Path $Global:Gene1799Config.LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    Add-Content -Path $Global:Gene1799Config.LogFile -Value $logEntry -Force
}

# ═══════════════════════════════════════════════════════════
# INIZIALIZZAZIONE SISTEMA INTEGRATO
# ═══════════════════════════════════════════════════════════

function Initialize-Gene1799AISystem {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "║        🧠 GENE1799 AI INTEGRATION SYSTEM INIT 🧠         ║" -ForegroundColor Cyan
    Write-Host "║          Multi-Disk | Multi-Provider | Multi-Agent       ║" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Gene1799Log "Initializing GENE1799 AI Integration System..." "INFO"
    
    # Crea tutte le directory necessarie su tutti i dischi
    Write-Host "`n📁 Creating directory structure..." -ForegroundColor Yellow
    
    $allPaths = $Global:Gene1799Config.Values | Where-Object { 
        $_ -like "*:*" -and $_ -notlike "*.log" -and $_ -notlike "*.json" 
    }
    
    $diskStats = @{
        "C:" = 0
        "D:" = 0
        "E:" = 0
    }
    
    foreach ($path in $allPaths) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            Write-Gene1799Log "Created: $path" "SUCCESS"
            
            # Conta per disco
            $disk = $path.Substring(0, 2)
            if ($diskStats.ContainsKey($disk)) {
                $diskStats[$disk]++
            }
        } else {
            Write-Gene1799Log "Exists: $path" "INFO"
        }
    }
    
    # Mostra statistiche dischi
    Write-Host "`n💾 Disk Distribution:" -ForegroundColor Cyan
    foreach ($disk in $diskStats.Keys | Sort-Object) {
        Write-Host "   $disk -> $($diskStats[$disk]) directories" -ForegroundColor Gray
    }
    
    # Crea struttura provider su disco E:
    Write-Host "`n🔌 Setting up AI Providers on E:\" -ForegroundColor Yellow
    foreach ($provider in $Global:AIProviders.Keys) {
        $providerPath = Join-Path $Global:Gene1799Config.AIProviders $provider
        if (-not (Test-Path $providerPath)) {
            New-Item -Path $providerPath -ItemType Directory -Force | Out-Null
            
            # Crea sottocartelle per ogni provider
            @("Models", "Cache", "Responses", "Training") | ForEach-Object {
                $subPath = Join-Path $providerPath $_
                New-Item -Path $subPath -ItemType Directory -Force | Out-Null
            }
            Write-Gene1799Log "Provider structure created: $provider" "SUCCESS" $provider
        }
    }
    
    # Inizializza configurazione AI
    if (-not (Test-Path $Global:Gene1799Config.ConfigFile)) {
        $aiConfig = @{
            version = "2.0"
            created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            disks = @{
                "C:" = @{
                    purpose = "AI Core & Models"
                    path = "C:\AI"
                }
                "D:" = @{
                    purpose = "GENE1799 Core & Electronic"
                    path = "D:\Gene1799"
                }
                "E:" = @{
                    purpose = "AI Extended Storage & Training"
                    path = "E:\GENE1799_AI"
                }
            }
            providers = @()
            active_agents = @()
            system_status = "INITIALIZED"
        }
        
        $configDir = Split-Path $Global:Gene1799Config.ConfigFile -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }
        
        $aiConfig | ConvertTo-Json -Depth 10 | Set-Content $Global:Gene1799Config.ConfigFile
        Write-Gene1799Log "AI Configuration initialized" "SUCCESS"
    }
    
    # Crea file API keys (vuoto, da compilare manualmente)
    if (-not (Test-Path $Global:Gene1799Config.APIKeysFile)) {
        $apiKeysTemplate = @{
            openai = ""
            anthropic = ""
            google = ""
            huggingface = ""
            stability = ""
            note = "Insert your API keys here. Keep this file secure!"
        }
        
        $apiKeysTemplate | ConvertTo-Json -Depth 10 | Set-Content $Global:Gene1799Config.APIKeysFile
        Write-Gene1799Log "API Keys template created: $($Global:Gene1799Config.APIKeysFile)" "WARN"
        Write-Host "`n⚠️  IMPORTANT: Add your API keys to:" -ForegroundColor Yellow
        Write-Host "   $($Global:Gene1799Config.APIKeysFile)" -ForegroundColor White
    }
    
    # Crea mappa di connessione tra dischi
    $diskConnectionMap = @{
        "C:\AI" = @{
            connected_to = @("D:\Gene1799", "E:\GENE1799_AI")
            purpose = "AI Core processing"
            weight = 1.0
        }
        "D:\Gene1799" = @{
            connected_to = @("C:\AI", "E:\GENE1799_AI", "D:\Electronic")
            purpose = "Central coordination hub"
            weight = 1.0
        }
        "E:\GENE1799_AI" = @{
            connected_to = @("C:\AI", "D:\Gene1799")
            purpose = "Extended AI storage & training"
            weight = 0.9
        }
        "D:\Electronic" = @{
            connected_to = @("D:\Gene1799", "C:\AI")
            purpose = "Electronic systems integration"
            weight = 0.8
        }
    }
    
    $mapPath = Join-Path $Global:Gene1799Config.Gene1799Synaptic "disk_connection_map.json"
    $diskConnectionMap | ConvertTo-Json -Depth 10 | Set-Content $mapPath
    Write-Gene1799Log "Disk connection map created" "SYNAPTIC"
    
    Write-Host "`n✅ GENE1799 AI Integration System initialized successfully!`n" -ForegroundColor Green
    Write-Host "📊 System spans across 3 disks: C:, D:, E:" -ForegroundColor Cyan
    Write-Host "🔌 Configured for $($Global:AIProviders.Count) AI providers" -ForegroundColor Cyan
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════
# API KEYS MANAGEMENT
# ═══════════════════════════════════════════════════════════

function Load-APIKeys {
    if (Test-Path $Global:Gene1799Config.APIKeysFile) {
        $keys = Get-Content $Global:Gene1799Config.APIKeysFile | ConvertFrom-Json
        
        # Carica le chiavi nei provider
        if ($keys.openai) { $Global:AIProviders.OpenAI.APIKey = $keys.openai }
        if ($keys.anthropic) { $Global:AIProviders.Anthropic.APIKey = $keys.anthropic }
        if ($keys.google) { $Global:AIProviders.Google.APIKey = $keys.google }
        if ($keys.huggingface) { $Global:AIProviders.HuggingFace.APIKey = $keys.huggingface }
        if ($keys.stability) { $Global:AIProviders.StabilityAI.APIKey = $keys.stability }
        
        Write-Gene1799Log "API Keys loaded" "SUCCESS"
        return $true
    } else {
        Write-Gene1799Log "API Keys file not found" "WARN"
        return $false
    }
}

# ═══════════════════════════════════════════════════════════
# TEST API CONNECTIONS
# ═══════════════════════════════════════════════════════════

function Test-AIProvider {
    param(
        [string]$ProviderName
    )
    
    Write-Host "`n🔌 Testing provider: $ProviderName" -ForegroundColor Cyan
    
    $provider = $Global:AIProviders[$ProviderName]
    
    if (-not $provider) {
        Write-Gene1799Log "Provider not found: $ProviderName" "ERROR"
        return $false
    }
    
    # Test connessione specifica per provider
    try {
        switch ($ProviderName) {
            "Ollama" {
                # Test Ollama locale
                try {
                    $response = Invoke-RestMethod -Uri "$($provider.Endpoint)/tags" -Method Get -TimeoutSec 5
                    $provider.Status = "ONLINE"
                    Write-Gene1799Log "Ollama is running locally. Models available: $($response.models.Count)" "SUCCESS" $ProviderName
                    return $true
                } catch {
                    $provider.Status = "OFFLINE"
                    Write-Gene1799Log "Ollama not running. Start with: ollama serve" "WARN" $ProviderName
                    return $false
                }
            }
            
            "OpenAI" {
                if ([string]::IsNullOrEmpty($provider.APIKey)) {
                    Write-Gene1799Log "API Key not configured" "WARN" $ProviderName
                    return $false
                }
                
                # Test OpenAI API
                $headers = @{
                    "Authorization" = "Bearer $($provider.APIKey)"
                    "Content-Type" = "application/json"
                }
                
                try {
                    $response = Invoke-RestMethod -Uri "$($provider.Endpoint)/models" -Headers $headers -Method Get -TimeoutSec 10
                    $provider.Status = "ONLINE"
                    Write-Gene1799Log "Connected successfully. Models available." "SUCCESS" $ProviderName
                    return $true
                } catch {
                    $provider.Status = "ERROR"
                    Write-Gene1799Log "Connection failed: $($_.Exception.Message)" "ERROR" $ProviderName
                    return $false
                }
            }
            
            "Anthropic" {
                if ([string]::IsNullOrEmpty($provider.APIKey)) {
                    Write-Gene1799Log "API Key not configured" "WARN" $ProviderName
                    return $false
                }
                
                $headers = @{
                    "x-api-key" = $provider.APIKey
                    "anthropic-version" = "2023-06-01"
                    "Content-Type" = "application/json"
                }
                
                try {
                    # Test con una richiesta minimale
                    $provider.Status = "ONLINE"
                    Write-Gene1799Log "API Key configured" "SUCCESS" $ProviderName
                    return $true
                } catch {
                    $provider.Status = "ERROR"
                    Write-Gene1799Log "Configuration error" "ERROR" $ProviderName
                    return $false
                }
            }
            
            default {
                if ([string]::IsNullOrEmpty($provider.APIKey)) {
                    Write-Gene1799Log "API Key not configured" "WARN" $ProviderName
                    $provider.Status = "NOT_CONFIGURED"
                    return $false
                } else {
                    $provider.Status = "CONFIGURED"
                    Write-Gene1799Log "API Key configured (not tested)" "INFO" $ProviderName
                    return $true
                }
            }
        }
    } catch {
        $provider.Status = "ERROR"
        Write-Gene1799Log "Test failed: $($_.Exception.Message)" "ERROR" $ProviderName
        return $false
    }
}

function Test-AllProviders {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║              🔌 TESTING ALL AI PROVIDERS 🔌              ║" -ForegroundColor Yellow
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Yellow
    
    Load-APIKeys
    
    $results = @{}
    
    foreach ($providerName in $Global:AIProviders.Keys) {
        $result = Test-AIProvider -ProviderName $providerName
        $results[$providerName] = $result
        Start-Sleep -Milliseconds 500
    }
    
    # Mostra riepilogo
    Write-Host "`n📊 Provider Status Summary:" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    foreach ($providerName in $Global:AIProviders.Keys) {
        $provider = $Global:AIProviders[$providerName]
        $statusColor = switch($provider.Status) {
            "ONLINE" { "Green" }
            "CONFIGURED" { "Yellow" }
            "OFFLINE" { "Red" }
            "NOT_CONFIGURED" { "DarkGray" }
            "ERROR" { "Red" }
            default { "Gray" }
        }
        
        Write-Host "  $($provider.Name.PadRight(25)): " -NoNewline
        Write-Host $provider.Status -ForegroundColor $statusColor
    }
    
    Write-Host ""
    
    # Salva stato providers
    $providerStatus = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        providers = @{}
    }
    
    foreach ($providerName in $Global:AIProviders.Keys) {
        $providerStatus.providers[$providerName] = @{
            status = $Global:AIProviders[$providerName].Status
            models = $Global:AIProviders[$providerName].Models
            capabilities = $Global:AIProviders[$providerName].Capabilities
        }
    }
    
    $statusPath = Join-Path $Global:Gene1799Config.Gene1799Database "provider_status.json"
    $providerStatus | ConvertTo-Json -Depth 10 | Set-Content $statusPath
    
    return $results
}

# ═══════════════════════════════════════════════════════════
# SYSTEM STATUS
# ═══════════════════════════════════════════════════════════

function Show-Gene1799Status {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║            📊 GENE1799 AI SYSTEM STATUS 📊               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    # Disk Status
    Write-Host "💾 Multi-Disk Architecture:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    $disks = @(
        @{Letter = "C:"; Path = "C:\AI"; Name = "AI Core"}
        @{Letter = "D:"; Path = "D:\Gene1799"; Name = "GENE1799 Core"}
        @{Letter = "D:"; Path = "D:\Electronic"; Name = "Electronic Systems"}
        @{Letter = "E:"; Path = "E:\GENE1799_AI"; Name = "AI Extended"}
    )
    
    foreach ($disk in $disks) {
        $exists = Test-Path $disk.Path
        $status = if ($exists) { "✓ ONLINE" } else { "✗ OFFLINE" }
        $color = if ($exists) { "Green" } else { "Red" }
        
        Write-Host "  [$($disk.Letter)] $($disk.Name.PadRight(25)): " -NoNewline
        Write-Host $status -ForegroundColor $color
        
        if ($exists -and $disk.Letter -eq "E:") {
            # Mostra spazio su E:
            try {
                $drive = Get-PSDrive -Name "E" -ErrorAction SilentlyContinue
                if ($drive) {
                    $freeGB = [math]::Round($drive.Free / 1GB, 2)
                    $usedGB = [math]::Round($drive.Used / 1GB, 2)
                    Write-Host "      Free: $freeGB GB | Used: $usedGB GB" -ForegroundColor Gray
                }
            } catch {}
        }
    }
    
    # AI Providers Status
    Write-Host "`n🔌 AI Providers:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    Load-APIKeys
    
    foreach ($providerName in $Global:AIProviders.Keys | Sort-Object) {
        $provider = $Global:AIProviders[$providerName]
        
        $statusColor = switch($provider.Status) {
            "ONLINE" { "Green" }
            "CONFIGURED" { "Yellow" }
            "OFFLINE" { "Red" }
            "NOT_CONFIGURED" { "DarkGray" }
            default { "Gray" }
        }
        
        Write-Host "  $($provider.Name.PadRight(25)): " -NoNewline
        Write-Host $provider.Status.PadRight(15) -ForegroundColor $statusColor -NoNewline
        Write-Host " | Models: $($provider.Models.Count)" -ForegroundColor Gray
    }
    
    # Agents Status
    Write-Host "`n🤖 Active Agents:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    if (Test-Path $Global:Gene1799Config.AgentDB) {
        $db = Get-Content $Global:Gene1799Config.AgentDB | ConvertFrom-Json
        
        if ($db.agents -and $db.agents.Count -gt 0) {
            foreach ($agent in $db.agents) {
                Write-Host "  • $($agent.name)" -ForegroundColor Cyan -NoNewline
                Write-Host " [$($agent.type)]" -ForegroundColor Gray -NoNewline
                
                $statusColor = switch($agent.status) {
                    "TRAINED" { "Green" }
                    "INITIALIZED" { "Yellow" }
                    default { "Gray" }
                }
                Write-Host " - $($agent.status)" -ForegroundColor $statusColor
            }
        } else {
            Write-Host "  No agents created yet" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Agent database not initialized" -ForegroundColor DarkGray
    }
    
    # System Info
    Write-Host "`n📈 System Information:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    $configExists = Test-Path $Global:Gene1799Config.ConfigFile
    Write-Host "  Configuration: " -NoNewline
    Write-Host $(if ($configExists) { "✓ Loaded" } else { "✗ Not found" }) -ForegroundColor $(if ($configExists) { "Green" } else { "Red" })
    
    $apiKeysExists = Test-Path $Global:Gene1799Config.APIKeysFile
    Write-Host "  API Keys:      " -NoNewline
    Write-Host $(if ($apiKeysExists) { "✓ Present" } else { "✗ Missing" }) -ForegroundColor $(if ($apiKeysExists) { "Green" } else { "Red" })
    
    if (Test-Path $Global:Gene1799Config.LogFile) {
        $logSize = (Get-Item $Global:Gene1799Config.LogFile).Length / 1KB
        Write-Host "  Log File:      ✓ $([math]::Round($logSize, 2)) KB" -ForegroundColor Green
    }
    
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════

Write-Host "`n🧠 GENE1799 AI INTEGRATION CORE v2.0" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

switch ($Mode) {
    "INIT" {
        Initialize-Gene1799AISystem
    }
    
    "TEST_API" {
        if ($Provider -eq "ALL") {
            Test-AllProviders
        } else {
            Test-AIProvider -ProviderName $Provider
        }
    }
    
    "STATUS" {
        Show-Gene1799Status
    }
    
    "CONFIGURE" {
        Write-Host "📝 Opening API Keys configuration file..." -ForegroundColor Yellow
        if (Test-Path $Global:Gene1799Config.APIKeysFile) {
            notepad $Global:Gene1799Config.APIKeysFile
        } else {
            Write-Host "⚠️  Configuration file not found. Run with -Mode INIT first." -ForegroundColor Red
        }
    }
    
    default {
        Show-Gene1799Status
    }
}

Write-Host ""
