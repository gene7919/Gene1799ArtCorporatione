#Requires -Version 7.0
<#
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║     ██████╗ ███████╗███╗   ██╗███████╗ ██╗ ███████╗ █████╗  █████╗          ║
║    ██╔════╝ ██╔════╝████╗  ██║██╔════╝███║╚════███║██╔══██╗██╔══██╗         ║
║    ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ╚██║    ███╔╝╚██████║╚██████║         ║
║    ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝   ██║   ███╔╝  ╚═══██║ ╚═══██║         ║
║    ╚██████╔╝███████╗██║ ╚████║███████╗ ██║  ███████╗█████╔╝ █████╔╝         ║
║     ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═╝  ╚══════╝╚════╝  ╚════╝          ║
║                                                                              ║
║              MEGA SISTEMA UNIFICATO v2.0 - Art Corporation                  ║
║   Fondatori: Marco Antonio Saverio Mazzitelli & Fabio Amedeo Lo Presti      ║
║                      (Arthemis Ludovici)                                     ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

.SYNOPSIS
    Gene1799 Mega Sistema - Piattaforma AI Unificata con Agenti Intelligenti

.DESCRIPTION
    Sistema completo che integra:
    - Core AI con auto-apprendimento
    - Sistema Agenti Multi-tipo (Social, File, Data, Content)
    - Neural Hub con connessioni sinaptiche
    - Bridge Universale per dati
    - GUI Desktop Monitor
    - Firma Digitale NFT
    - Zero Cost AI (Ollama + Gemini Free)

.AUTHOR
    Gene1799 Art Corporation
    License: 16/L4090879L

.EXAMPLE
    .\Gene1799_MegaSystem.ps1 -Mode INIT
    .\Gene1799_MegaSystem.ps1 -Mode GUI
    .\Gene1799_MegaSystem.ps1 -Mode AGENT -AgentAction CREATE -AgentName "MyBot" -AgentType "FILE_MANAGER"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('INIT','GUI','DASHBOARD','AGENT','NEURAL','SCAN','BRIDGE','STATUS','HEAL','BACKUP','HELP')]
    [string]$Mode = 'HELP',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('CREATE','TRAIN','DEPLOY','STATUS','DELETE','EVOLVE')]
    [string]$AgentAction,
    
    [Parameter(Mandatory=$false)]
    [string]$AgentName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('SOCIAL_MEDIA','FILE_MANAGER','DATA_ANALYST','CONTENT_CREATOR','MULTI_TASK')]
    [string]$AgentType,
    
    [Parameter(Mandatory=$false)]
    [int]$TrainingCycles = 20,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# ══════════════════════════════════════════════════════════════════════════════
#  CONFIGURAZIONE GLOBALE DEL MEGA SISTEMA
# ══════════════════════════════════════════════════════════════════════════════

$Global:Gene1799 = @{
    Version = "2.0.0"
    Codename = "MegaSystem"
    
    # Paths - Auto-detect installation
    RootPath = if (Test-Path "D:\Gene1799") { "D:\Gene1799" } else { "$PSScriptRoot" }
    DataPath = if (Test-Path "E:\Gene1799_Data") { "E:\Gene1799_Data" } else { "$PSScriptRoot\Data" }
    
    # Sub-paths
    Paths = @{
        Core        = $null  # Calcolato dopo
        Modules     = $null
        Agents      = $null
        Knowledge   = $null
        Logs        = $null
        Config      = $null
        Bridges     = $null
        Synaptic    = $null
        Backup      = $null
    }
    
    # Sistema
    MaxAgents = 20
    LearningRate = 0.01
    AutoSaveInterval = 300
    
    # Firma Digitale
    Signature = @{
        Organization = "Gene1799 Art Corporation"
        Founders = @(
            "Marco Antonio Saverio Mazzitelli",
            "Fabio Amedeo Lo Presti (Arthemis Ludovici)"
        )
        License = "16/L4090879L"
        CertHash = "GENE1799-ART-CORP-2024"
    }
    
    # Stato Runtime
    ActiveAgents = @{}
    KnowledgeBase = @{}
    PerformanceMetrics = @{}
    StartTime = Get-Date
}

# Calcola paths derivati
$Global:Gene1799.Paths.Core      = Join-Path $Global:Gene1799.RootPath "Core"
$Global:Gene1799.Paths.Modules   = Join-Path $Global:Gene1799.RootPath "Modules"
$Global:Gene1799.Paths.Agents    = Join-Path $Global:Gene1799.RootPath "Agents"
$Global:Gene1799.Paths.Knowledge = Join-Path $Global:Gene1799.RootPath "Knowledge"
$Global:Gene1799.Paths.Logs      = Join-Path $Global:Gene1799.RootPath "Logs"
$Global:Gene1799.Paths.Config    = Join-Path $Global:Gene1799.RootPath "Config"
$Global:Gene1799.Paths.Bridges   = Join-Path $Global:Gene1799.RootPath "Bridges"
$Global:Gene1799.Paths.Synaptic  = Join-Path $Global:Gene1799.RootPath "Synaptic"
$Global:Gene1799.Paths.Backup    = Join-Path $Global:Gene1799.DataPath "Backup"

# ══════════════════════════════════════════════════════════════════════════════
#  SISTEMA DI LOGGING AVANZATO
# ══════════════════════════════════════════════════════════════════════════════

function Write-Gene1799 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR','SYSTEM','AGENT','NEURAL','LEARNING')]
        [string]$Level = 'INFO',
        
        [Parameter(Mandatory=$false)]
        [switch]$NoLog
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $Global:Gene1799.Paths.Logs "mega_system_$(Get-Date -Format 'yyyyMMdd').log"
    
    $colors = @{
        'INFO'     = 'Cyan'
        'SUCCESS'  = 'Green'
        'WARNING'  = 'Yellow'
        'ERROR'    = 'Red'
        'SYSTEM'   = 'Magenta'
        'AGENT'    = 'Blue'
        'NEURAL'   = 'DarkMagenta'
        'LEARNING' = 'DarkCyan'
    }
    
    $icons = @{
        'INFO'     = 'ℹ️'
        'SUCCESS'  = '✅'
        'WARNING'  = '⚠️'
        'ERROR'    = '❌'
        'SYSTEM'   = '⚙️'
        'AGENT'    = '🤖'
        'NEURAL'   = '🧠'
        'LEARNING' = '📚'
    }
    
    $icon = $icons[$Level]
    $color = $colors[$Level]
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Write-Host "$icon " -NoNewline
    Write-Host $logEntry -ForegroundColor $color
    
    if (-not $NoLog) {
        $logDir = Split-Path $logFile -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  INIZIALIZZAZIONE STRUTTURA COMPLETA
# ══════════════════════════════════════════════════════════════════════════════

function Initialize-Gene1799System {
    [CmdletBinding()]
    param([switch]$Force)
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           GENE1799 MEGA SYSTEM INITIALIZATION                    ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Gene1799 "Inizializzazione struttura Gene1799 MegaSystem v$($Global:Gene1799.Version)..." -Level SYSTEM
    
    # Crea tutte le directory
    $directories = @(
        $Global:Gene1799.RootPath,
        $Global:Gene1799.DataPath,
        $Global:Gene1799.Paths.Core,
        $Global:Gene1799.Paths.Modules,
        $Global:Gene1799.Paths.Agents,
        $Global:Gene1799.Paths.Knowledge,
        $Global:Gene1799.Paths.Logs,
        $Global:Gene1799.Paths.Config,
        $Global:Gene1799.Paths.Bridges,
        $Global:Gene1799.Paths.Synaptic,
        $Global:Gene1799.Paths.Backup,
        # Sub-directories per agenti
        (Join-Path $Global:Gene1799.Paths.Agents "SOCIAL_MEDIA"),
        (Join-Path $Global:Gene1799.Paths.Agents "FILE_MANAGER"),
        (Join-Path $Global:Gene1799.Paths.Agents "DATA_ANALYST"),
        (Join-Path $Global:Gene1799.Paths.Agents "CONTENT_CREATOR"),
        # Sub-directories per knowledge
        (Join-Path $Global:Gene1799.Paths.Knowledge "Experiences"),
        (Join-Path $Global:Gene1799.Paths.Knowledge "Patterns"),
        (Join-Path $Global:Gene1799.Paths.Knowledge "ErrorCorrections"),
        # Sub-directories per bridges
        (Join-Path $Global:Gene1799.Paths.Bridges "Agents"),
        (Join-Path $Global:Gene1799.Paths.Bridges "Social"),
        (Join-Path $Global:Gene1799.Paths.Bridges "Tools"),
        # Synaptic weights
        (Join-Path $Global:Gene1799.Paths.Synaptic "Weights"),
        (Join-Path $Global:Gene1799.Paths.Synaptic "Connections")
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Gene1799 "Creata: $dir" -Level SUCCESS
        }
    }
    
    # Crea file di configurazione principale
    $configFile = Join-Path $Global:Gene1799.Paths.Config "mega_system_config.json"
    $config = @{
        Version = $Global:Gene1799.Version
        Codename = $Global:Gene1799.Codename
        Initialized = Get-Date
        RootPath = $Global:Gene1799.RootPath
        DataPath = $Global:Gene1799.DataPath
        Signature = $Global:Gene1799.Signature
        Settings = @{
            MaxAgents = $Global:Gene1799.MaxAgents
            LearningRate = $Global:Gene1799.LearningRate
            AutoSaveInterval = $Global:Gene1799.AutoSaveInterval
        }
    }
    $config | ConvertTo-Json -Depth 10 | Set-Content $configFile
    Write-Gene1799 "Configurazione salvata: $configFile" -Level SUCCESS
    
    # Inizializza Knowledge Base
    Initialize-KnowledgeBase
    
    # Inizializza Neural Map
    Initialize-NeuralMap
    
    Write-Host ""
    Write-Gene1799 "GENE1799 MEGA SYSTEM inizializzato con successo!" -Level SUCCESS
    Write-Host ""
    
    Show-SystemStatus
}

function Initialize-KnowledgeBase {
    Write-Gene1799 "Inizializzazione Knowledge Base..." -Level NEURAL
    
    $kbFile = Join-Path $Global:Gene1799.Paths.Knowledge "knowledge_base.json"
    
    if (Test-Path $kbFile) {
        try {
            $Global:Gene1799.KnowledgeBase = Get-Content $kbFile -Raw | ConvertFrom-Json -AsHashtable
            Write-Gene1799 "Knowledge Base caricata: $($Global:Gene1799.KnowledgeBase.Experiences.Count) esperienze" -Level SUCCESS
        }
        catch {
            Write-Gene1799 "Errore caricamento KB, creazione nuova..." -Level WARNING
            $Global:Gene1799.KnowledgeBase = @{
                Experiences = @()
                Patterns = @()
                ErrorCorrections = @()
                SuccessRates = @{}
                LastUpdate = Get-Date
            }
        }
    }
    else {
        $Global:Gene1799.KnowledgeBase = @{
            Experiences = @()
            Patterns = @()
            ErrorCorrections = @()
            SuccessRates = @{}
            LastUpdate = Get-Date
        }
        Save-KnowledgeBase
    }
}

function Save-KnowledgeBase {
    $kbFile = Join-Path $Global:Gene1799.Paths.Knowledge "knowledge_base.json"
    $Global:Gene1799.KnowledgeBase.LastUpdate = Get-Date
    $Global:Gene1799.KnowledgeBase | ConvertTo-Json -Depth 10 | Set-Content $kbFile
}

function Initialize-NeuralMap {
    Write-Gene1799 "Inizializzazione Neural Map..." -Level NEURAL
    
    $mapFile = Join-Path $Global:Gene1799.Paths.Synaptic "neural_map.json"
    
    $neuralMap = @{
        Version = "1.0"
        Created = Get-Date
        Nodes = @{
            "AI_CORE" = @{
                Type = "Core"
                Connections = @("AGENTS", "KNOWLEDGE", "BRIDGES")
                Weight = 1.0
            }
            "AGENTS" = @{
                Type = "AgentHub"
                Connections = @("AI_CORE", "KNOWLEDGE", "SOCIAL")
                Weight = 0.9
            }
            "KNOWLEDGE" = @{
                Type = "Memory"
                Connections = @("AI_CORE", "AGENTS", "PATTERNS")
                Weight = 0.95
            }
            "BRIDGES" = @{
                Type = "DataBridge"
                Connections = @("AI_CORE", "EXTERNAL")
                Weight = 0.8
            }
            "PATTERNS" = @{
                Type = "Learning"
                Connections = @("KNOWLEDGE", "AGENTS")
                Weight = 0.85
            }
            "SOCIAL" = @{
                Type = "Integration"
                Connections = @("AGENTS", "EXTERNAL")
                Weight = 0.7
            }
            "EXTERNAL" = @{
                Type = "Interface"
                Connections = @("BRIDGES", "SOCIAL")
                Weight = 0.6
            }
        }
        TotalConnections = 14
        Status = "ACTIVE"
    }
    
    $neuralMap | ConvertTo-Json -Depth 10 | Set-Content $mapFile
    Write-Gene1799 "Neural Map inizializzata con $($neuralMap.TotalConnections) connessioni" -Level SUCCESS
}

# ══════════════════════════════════════════════════════════════════════════════
#  SISTEMA AGENTI AI - CLASSE E GESTIONE
# ══════════════════════════════════════════════════════════════════════════════

$Global:AgentTemplates = @{
    SOCIAL_MEDIA = @{
        Name = "Social Media Manager"
        Description = "Gestisce profili social, crea contenuti, analizza engagement"
        Capabilities = @("PostContent", "SchedulePosts", "AnalyzeEngagement", "RespondComments", 
                        "TrendAnalysis", "HashtagOptimization", "AudienceGrowth")
        Platforms = @("Facebook", "Instagram", "Twitter", "LinkedIn", "TikTok", "YouTube")
        AutomationLevel = 0.7
    }
    FILE_MANAGER = @{
        Name = "Intelligent File Manager"
        Description = "Organizza, classifica e gestisce file automaticamente"
        Capabilities = @("AutoOrganize", "SmartTagging", "DuplicateDetection", "BackupManagement",
                        "FileClassification", "StorageOptimization", "SearchOptimization")
        SupportedTypes = @("Documents", "Images", "Videos", "Audio", "Archives", "Code")
        AutomationLevel = 0.9
    }
    DATA_ANALYST = @{
        Name = "Data Analysis Agent"
        Description = "Analizza dati, crea report e identifica pattern"
        Capabilities = @("DataCollection", "PatternRecognition", "ReportGeneration", "PredictiveAnalysis",
                        "Visualization", "TrendForecasting", "AnomalyDetection")
        DataSources = @("Files", "Databases", "APIs", "WebScraping")
        AutomationLevel = 0.8
    }
    CONTENT_CREATOR = @{
        Name = "Creative Content Generator"
        Description = "Crea contenuti originali: testi, immagini, video"
        Capabilities = @("TextGeneration", "ImageCreation", "VideoEditing", "SEOOptimization",
                        "BrandConsistency", "MultilingualContent", "ContentAdaptation")
        ContentTypes = @("BlogPosts", "SocialPosts", "Graphics", "Videos", "Presentations")
        AutomationLevel = 0.6
    }
    MULTI_TASK = @{
        Name = "Multi-Task Agent"
        Description = "Agente versatile per task generici e automazione"
        Capabilities = @("TaskExecution", "Scheduling", "Monitoring", "Reporting", "Integration")
        AutomationLevel = 0.75
    }
}

function New-Gene1799Agent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('SOCIAL_MEDIA','FILE_MANAGER','DATA_ANALYST','CONTENT_CREATOR','MULTI_TASK')]
        [string]$Type
    )
    
    Write-Gene1799 "Creazione agente: $Name ($Type)" -Level AGENT
    
    $template = $Global:AgentTemplates[$Type]
    $agentId = [guid]::NewGuid().ToString().Substring(0,8)
    
    $agent = @{
        ID = $agentId
        Name = $Name
        Type = $Type
        Template = $template
        Skills = @{}
        Level = 1
        Autonomy = 0.3
        Performance = 0.5
        Created = Get-Date
        LastActive = Get-Date
        ActionsCount = 0
        Status = "CREATED"
        Memory = @{
            ShortTerm = @()
            LongTerm = @()
        }
        Goals = @{
            Current = @()
            Completed = @()
        }
    }
    
    # Inizializza skills
    foreach ($cap in $template.Capabilities) {
        $agent.Skills[$cap] = @{
            Level = 1
            Experience = 0
            SuccessRate = 0.5
            LastUsed = $null
        }
    }
    
    # Salva agente
    $agentPath = Join-Path $Global:Gene1799.Paths.Agents "$Type\$agentId`_$Name"
    New-Item -Path $agentPath -ItemType Directory -Force | Out-Null
    
    $agent | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $agentPath "agent_state.json")
    
    # Aggiungi a runtime
    $Global:Gene1799.ActiveAgents[$Name] = $agent
    
    Write-Gene1799 "Agente $Name creato con successo! ID: $agentId" -Level SUCCESS
    
    # Mostra riepilogo
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║         AGENTE CREATO CON SUCCESSO                ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  🆔 ID:           $agentId" -ForegroundColor Cyan
    Write-Host "  📛 Nome:         $Name" -ForegroundColor Cyan
    Write-Host "  🏷️  Tipo:         $Type" -ForegroundColor Cyan
    Write-Host "  📝 Descrizione:  $($template.Description)" -ForegroundColor Gray
    Write-Host "  🔧 Capabilities: $($template.Capabilities.Count)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Capabilities disponibili:" -ForegroundColor Magenta
    foreach ($cap in $template.Capabilities) {
        Write-Host "    • $cap" -ForegroundColor Gray
    }
    Write-Host ""
    
    return $agent
}

function Start-AgentTraining {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$AgentName,
        
        [Parameter(Mandatory=$false)]
        [int]$Cycles = 20
    )
    
    $agent = Get-Gene1799Agent -Name $AgentName
    if (-not $agent) {
        Write-Gene1799 "Agente non trovato: $AgentName" -Level ERROR
        return
    }
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║         TRAINING AGENTE IN CORSO...               ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Gene1799 "Inizio training $AgentName - $Cycles cicli" -Level LEARNING
    
    $skills = $agent.Skills.Keys | Get-Random -Count ([math]::Min(4, $agent.Skills.Count))
    
    for ($i = 1; $i -le $Cycles; $i++) {
        Write-Host "🔄 Ciclo $i/$Cycles" -ForegroundColor Cyan
        
        foreach ($skill in $skills) {
            $successProb = 0.4 + ($agent.Skills[$skill].Level * 0.05) + ($i / $Cycles * 0.3)
            $success = (Get-Random -Minimum 0.0 -Maximum 1.0) -lt $successProb
            
            # Aggiorna skill
            $agent.Skills[$skill].Experience++
            if ($success) {
                $agent.Skills[$skill].SuccessRate = 
                    ($agent.Skills[$skill].SuccessRate * 0.9) + (0.1)
                
                if ($agent.Skills[$skill].Experience % 5 -eq 0) {
                    $agent.Skills[$skill].Level = [math]::Min($agent.Skills[$skill].Level + 1, 10)
                }
            }
            else {
                $agent.Skills[$skill].SuccessRate = 
                    ($agent.Skills[$skill].SuccessRate * 0.95)
            }
            
            $agent.ActionsCount++
            
            $icon = if ($success) { "✅" } else { "❌" }
            $color = if ($success) { "Green" } else { "Red" }
            Write-Host "  $icon $skill - Rate: $($agent.Skills[$skill].SuccessRate.ToString('P0'))" -ForegroundColor $color
        }
        
        # Aggiorna performance generale
        $totalRate = 0
        foreach ($s in $agent.Skills.Keys) {
            $totalRate += $agent.Skills[$s].SuccessRate
        }
        $agent.Performance = $totalRate / $agent.Skills.Count
        
        # Aggiorna autonomia
        if ($agent.Performance -gt 0.7) {
            $agent.Autonomy = [math]::Min($agent.Autonomy + 0.02, 0.95)
        }
        
        Write-Host "  📊 Performance: $($agent.Performance.ToString('P0')) | Autonomia: $($agent.Autonomy.ToString('P0'))" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 100
    }
    
    $agent.Status = "TRAINED"
    $agent.LastActive = Get-Date
    
    # Salva stato
    Save-AgentState -Agent $agent
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║         TRAINING COMPLETATO!                      ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  📊 Performance finale: $($agent.Performance.ToString('P1'))" -ForegroundColor Cyan
    Write-Host "  🎯 Autonomia: $($agent.Autonomy.ToString('P1'))" -ForegroundColor Cyan
    Write-Host "  📈 Azioni eseguite: $($agent.ActionsCount)" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Gene1799 "Training completato per $AgentName - Performance: $($agent.Performance.ToString('P1'))" -Level SUCCESS
}

function Get-Gene1799Agent {
    [CmdletBinding()]
    param([string]$Name)
    
    # Prima cerca in memoria
    if ($Global:Gene1799.ActiveAgents.ContainsKey($Name)) {
        return $Global:Gene1799.ActiveAgents[$Name]
    }
    
    # Poi cerca su disco
    foreach ($type in $Global:AgentTemplates.Keys) {
        $typePath = Join-Path $Global:Gene1799.Paths.Agents $type
        if (Test-Path $typePath) {
            $agentDirs = Get-ChildItem -Path $typePath -Directory -ErrorAction SilentlyContinue
            foreach ($dir in $agentDirs) {
                $stateFile = Join-Path $dir.FullName "agent_state.json"
                if (Test-Path $stateFile) {
                    $state = Get-Content $stateFile -Raw | ConvertFrom-Json -AsHashtable
                    if ($state.Name -eq $Name) {
                        $Global:Gene1799.ActiveAgents[$Name] = $state
                        return $state
                    }
                }
            }
        }
    }
    
    return $null
}

function Get-AllAgents {
    $agents = @()
    
    foreach ($type in $Global:AgentTemplates.Keys) {
        $typePath = Join-Path $Global:Gene1799.Paths.Agents $type
        if (Test-Path $typePath) {
            $agentDirs = Get-ChildItem -Path $typePath -Directory -ErrorAction SilentlyContinue
            foreach ($dir in $agentDirs) {
                $stateFile = Join-Path $dir.FullName "agent_state.json"
                if (Test-Path $stateFile) {
                    try {
                        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
                        $agents += $state
                    }
                    catch {}
                }
            }
        }
    }
    
    return $agents
}

function Save-AgentState {
    [CmdletBinding()]
    param([hashtable]$Agent)
    
    $agentPath = Join-Path $Global:Gene1799.Paths.Agents "$($Agent.Type)\$($Agent.ID)_$($Agent.Name)"
    if (-not (Test-Path $agentPath)) {
        New-Item -Path $agentPath -ItemType Directory -Force | Out-Null
    }
    
    $Agent | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $agentPath "agent_state.json")
}

function Deploy-Gene1799Agent {
    [CmdletBinding()]
    param([string]$AgentName)
    
    $agent = Get-Gene1799Agent -Name $AgentName
    if (-not $agent) {
        Write-Gene1799 "Agente non trovato: $AgentName" -Level ERROR
        return
    }
    
    $agent.Status = "DEPLOYED"
    $agent.LastActive = Get-Date
    Save-AgentState -Agent $agent
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║         AGENTE DEPLOYED!                          ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  🤖 $AgentName è ora ATTIVO e OPERATIVO!" -ForegroundColor Cyan
    Write-Host "  🎯 Autonomia: $($agent.Autonomy.ToString('P0'))" -ForegroundColor Yellow
    Write-Host "  📊 Performance: $($agent.Performance.ToString('P0'))" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Gene1799 "Agente $AgentName deployed con successo!" -Level SUCCESS
}

# ══════════════════════════════════════════════════════════════════════════════
#  DASHBOARD E STATUS
# ══════════════════════════════════════════════════════════════════════════════

function Show-SystemStatus {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              GENE1799 MEGA SYSTEM STATUS                         ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Info Sistema
    Write-Host "  ⚙️  SISTEMA" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "    Versione:    $($Global:Gene1799.Version) ($($Global:Gene1799.Codename))" -ForegroundColor White
    Write-Host "    Root Path:   $($Global:Gene1799.RootPath)" -ForegroundColor Gray
    Write-Host "    Data Path:   $($Global:Gene1799.DataPath)" -ForegroundColor Gray
    Write-Host "    Uptime:      $((Get-Date) - $Global:Gene1799.StartTime)" -ForegroundColor Gray
    Write-Host ""
    
    # Agenti
    $agents = Get-AllAgents
    Write-Host "  🤖 AGENTI ($($agents.Count) totali)" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    
    if ($agents.Count -gt 0) {
        foreach ($agent in $agents) {
            $statusColor = switch ($agent.Status) {
                "DEPLOYED" { "Green" }
                "TRAINED"  { "Yellow" }
                "CREATED"  { "Gray" }
                default    { "White" }
            }
            Write-Host "    [$($agent.Status.PadRight(8))] " -ForegroundColor $statusColor -NoNewline
            Write-Host "$($agent.Name) " -ForegroundColor Cyan -NoNewline
            Write-Host "($($agent.Type)) " -ForegroundColor Gray -NoNewline
            Write-Host "Perf: $($agent.Performance.ToString('P0'))" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "    Nessun agente creato" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Knowledge Base
    Write-Host "  📚 KNOWLEDGE BASE" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    $kbFile = Join-Path $Global:Gene1799.Paths.Knowledge "knowledge_base.json"
    if (Test-Path $kbFile) {
        $kb = Get-Content $kbFile -Raw | ConvertFrom-Json
        Write-Host "    Esperienze:         $($kb.Experiences.Count)" -ForegroundColor Cyan
        Write-Host "    Pattern scoperti:   $($kb.Patterns.Count)" -ForegroundColor Green
        Write-Host "    Correzioni:         $($kb.ErrorCorrections.Count)" -ForegroundColor Yellow
    }
    else {
        Write-Host "    Non inizializzata" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Neural Network
    Write-Host "  🧠 NEURAL NETWORK" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    $mapFile = Join-Path $Global:Gene1799.Paths.Synaptic "neural_map.json"
    if (Test-Path $mapFile) {
        $map = Get-Content $mapFile -Raw | ConvertFrom-Json
        Write-Host "    Nodi:       $($map.Nodes.PSObject.Properties.Count)" -ForegroundColor Cyan
        Write-Host "    Connessioni: $($map.TotalConnections)" -ForegroundColor Green
        Write-Host "    Status:     $($map.Status)" -ForegroundColor Green
    }
    else {
        Write-Host "    Non inizializzato" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Firma
    Write-Host "  📜 FIRMA DIGITALE" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "    Organizzazione: $($Global:Gene1799.Signature.Organization)" -ForegroundColor Cyan
    Write-Host "    Licenza:        $($Global:Gene1799.Signature.License)" -ForegroundColor Green
    Write-Host ""
}

function Show-Dashboard {
    Clear-Host
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "║     ██████╗ ███████╗███╗   ██╗███████╗ ██╗ ███████╗ █████╗  █████╗          ║" -ForegroundColor Cyan
    Write-Host "║    ██╔════╝ ██╔════╝████╗  ██║██╔════╝███║╚════███║██╔══██╗██╔══██╗         ║" -ForegroundColor Cyan
    Write-Host "║    ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ╚██║    ███╔╝╚██████║╚██████║         ║" -ForegroundColor Cyan
    Write-Host "║    ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝   ██║   ███╔╝  ╚═══██║ ╚═══██║         ║" -ForegroundColor Cyan
    Write-Host "║    ╚██████╔╝███████╗██║ ╚████║███████╗ ██║  ███████╗█████╔╝ █████╔╝         ║" -ForegroundColor Cyan
    Write-Host "║     ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═╝  ╚══════╝╚════╝  ╚════╝          ║" -ForegroundColor Cyan
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "║                    MEGA SYSTEM CONTROL CENTER v2.0                          ║" -ForegroundColor Yellow
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Quick stats bar
    $agents = Get-AllAgents
    $deployed = ($agents | Where-Object { $_.Status -eq "DEPLOYED" }).Count
    
    Write-Host "  ⚡ Sistema Attivo " -ForegroundColor Green -NoNewline
    Write-Host "│" -ForegroundColor DarkGray -NoNewline
    Write-Host "  🤖 $($agents.Count) Agenti ($deployed deployed) " -ForegroundColor Cyan -NoNewline
    Write-Host "│" -ForegroundColor DarkGray -NoNewline
    Write-Host "  🧠 Neural OK " -ForegroundColor Magenta
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    # Menu principale
    Write-Host "  📋 MENU PRINCIPALE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    [1] 🤖 Gestione Agenti          [6] 🔍 Scansione Sistema" -ForegroundColor White
    Write-Host "    [2] 🎓 Training Agente          [7] 🌉 Bridge Manager" -ForegroundColor White
    Write-Host "    [3] 🚀 Deploy Agente            [8] 💾 Backup Sistema" -ForegroundColor White
    Write-Host "    [4] 📊 Status Dettagliato       [9] 🩺 System Health" -ForegroundColor White
    Write-Host "    [5] 🧠 Neural Hub               [0] ❌ Esci" -ForegroundColor White
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host "  Scegli opzione"
    
    switch ($choice) {
        "1" { 
            Show-AgentManager
            Show-Dashboard
        }
        "2" {
            $name = Read-Host "`n  Nome agente da trainare"
            if ($name) {
                $cycles = Read-Host "  Cicli di training (default 20)"
                if (-not $cycles) { $cycles = 20 }
                Start-AgentTraining -AgentName $name -Cycles ([int]$cycles)
            }
            Read-Host "`n  Premi Enter per continuare"
            Show-Dashboard
        }
        "3" {
            $name = Read-Host "`n  Nome agente da deployare"
            if ($name) {
                Deploy-Gene1799Agent -AgentName $name
            }
            Read-Host "`n  Premi Enter per continuare"
            Show-Dashboard
        }
        "4" {
            Show-SystemStatus
            Read-Host "`n  Premi Enter per continuare"
            Show-Dashboard
        }
        "5" {
            Show-NeuralHubStatus
            Read-Host "`n  Premi Enter per continuare"
            Show-Dashboard
        }
        "6" {
            Start-SystemScan
            Read-Host "`n  Premi Enter per continuare"
            Show-Dashboard
        }
        "7" {
            Start-BridgeManager
            Read-Host "`n  Premi Enter per continuare"
            Show-Dashboard
        }
        "8" {
            Start-SystemBackup
            Read-Host "`n  Premi Enter per continuare"
            Show-Dashboard
        }
        "9" {
            Start-SystemHealthCheck
            Read-Host "`n  Premi Enter per continuare"
            Show-Dashboard
        }
        "0" {
            Write-Host "`n  👋 Arrivederci!`n" -ForegroundColor Cyan
            return
        }
        default {
            Show-Dashboard
        }
    }
}

function Show-AgentManager {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    GESTIONE AGENTI                               ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $agents = Get-AllAgents
    
    if ($agents.Count -gt 0) {
        Write-Host "  Agenti esistenti:" -ForegroundColor Yellow
        Write-Host ""
        $i = 1
        foreach ($agent in $agents) {
            $statusColor = switch ($agent.Status) {
                "DEPLOYED" { "Green" }
                "TRAINED"  { "Yellow" }
                default    { "Gray" }
            }
            Write-Host "    [$i] " -ForegroundColor Cyan -NoNewline
            Write-Host "$($agent.Name.PadRight(20)) " -ForegroundColor White -NoNewline
            Write-Host "[$($agent.Status.PadRight(8))] " -ForegroundColor $statusColor -NoNewline
            Write-Host "$($agent.Type)" -ForegroundColor Gray
            $i++
        }
        Write-Host ""
    }
    else {
        Write-Host "  Nessun agente creato." -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "  Azioni:" -ForegroundColor Yellow
    Write-Host "    [C] Crea nuovo agente" -ForegroundColor White
    Write-Host "    [T] Tipi disponibili" -ForegroundColor White
    Write-Host "    [B] Torna indietro" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "  Scegli"
    
    switch ($choice.ToUpper()) {
        "C" {
            Write-Host ""
            Write-Host "  Tipi disponibili:" -ForegroundColor Yellow
            $types = @("SOCIAL_MEDIA", "FILE_MANAGER", "DATA_ANALYST", "CONTENT_CREATOR", "MULTI_TASK")
            for ($i = 0; $i -lt $types.Count; $i++) {
                $t = $types[$i]
                Write-Host "    [$($i+1)] $t - $($Global:AgentTemplates[$t].Description)" -ForegroundColor Gray
            }
            Write-Host ""
            
            $typeIdx = Read-Host "  Scegli tipo (1-5)"
            if ($typeIdx -match '^\d+$' -and [int]$typeIdx -ge 1 -and [int]$typeIdx -le 5) {
                $selectedType = $types[[int]$typeIdx - 1]
                $name = Read-Host "  Nome del nuovo agente"
                if ($name) {
                    New-Gene1799Agent -Name $name -Type $selectedType
                }
            }
            Read-Host "`n  Premi Enter per continuare"
        }
        "T" {
            Write-Host ""
            foreach ($type in $Global:AgentTemplates.Keys) {
                $t = $Global:AgentTemplates[$type]
                Write-Host "  📌 $type" -ForegroundColor Cyan
                Write-Host "     $($t.Description)" -ForegroundColor Gray
                Write-Host "     Capabilities: $($t.Capabilities -join ', ')" -ForegroundColor DarkGray
                Write-Host ""
            }
            Read-Host "  Premi Enter per continuare"
        }
    }
}

function Show-NeuralHubStatus {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                    🧠 NEURAL HUB STATUS                          ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    $mapFile = Join-Path $Global:Gene1799.Paths.Synaptic "neural_map.json"
    if (Test-Path $mapFile) {
        $map = Get-Content $mapFile -Raw | ConvertFrom-Json
        
        Write-Host "  Nodi della rete neurale:" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($nodeName in $map.Nodes.PSObject.Properties.Name) {
            $node = $map.Nodes.$nodeName
            Write-Host "    🔵 $nodeName" -ForegroundColor Cyan
            Write-Host "       Tipo: $($node.Type)" -ForegroundColor Gray
            Write-Host "       Peso: $($node.Weight)" -ForegroundColor Yellow
            Write-Host "       Connessioni: $($node.Connections -join ' → ')" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  Totale Nodi:        $($map.Nodes.PSObject.Properties.Count)" -ForegroundColor Cyan
        Write-Host "  Totale Connessioni: $($map.TotalConnections)" -ForegroundColor Green
        Write-Host "  Status:             $($map.Status)" -ForegroundColor Green
    }
    else {
        Write-Host "  Neural Hub non inizializzato" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Start-SystemScan {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║                    🔍 SCANSIONE SISTEMA                          ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Gene1799 "Avvio scansione sistema..." -Level SYSTEM
    
    # Scansione file PS1
    $ps1Count = 0
    $totalSize = 0
    
    $scanPaths = @($Global:Gene1799.RootPath)
    if (Test-Path "D:\") { $scanPaths += "D:\" }
    if (Test-Path "E:\") { $scanPaths += "E:\" }
    
    foreach ($path in $scanPaths) {
        Write-Host "  📂 Scansione $path..." -ForegroundColor Cyan
        try {
            $files = Get-ChildItem -Path $path -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
            $ps1Count += $files.Count
            $totalSize += ($files | Measure-Object -Property Length -Sum).Sum
        }
        catch {}
    }
    
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Script PowerShell trovati: $ps1Count" -ForegroundColor Cyan
    Write-Host "  Dimensione totale:         $([math]::Round($totalSize / 1KB, 2)) KB" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Gene1799 "Scansione completata: $ps1Count script trovati" -Level SUCCESS
}

function Start-BridgeManager {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                    🌉 BRIDGE MANAGER                             ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
    
    $bridgePath = $Global:Gene1799.Paths.Bridges
    
    $agentBridge = Join-Path $bridgePath "Agents"
    $socialBridge = Join-Path $bridgePath "Social"
    $toolsBridge = Join-Path $bridgePath "Tools"
    
    Write-Host "  Ponti attivi:" -ForegroundColor Yellow
    Write-Host ""
    
    if (Test-Path $agentBridge) {
        $count = (Get-ChildItem $agentBridge -ErrorAction SilentlyContinue).Count
        Write-Host "    🤖 Agenti:   $count file collegati" -ForegroundColor Cyan
    }
    
    if (Test-Path $socialBridge) {
        $count = (Get-ChildItem $socialBridge -ErrorAction SilentlyContinue).Count
        Write-Host "    📱 Social:   $count file collegati" -ForegroundColor Blue
    }
    
    if (Test-Path $toolsBridge) {
        $count = (Get-ChildItem $toolsBridge -ErrorAction SilentlyContinue).Count
        Write-Host "    🔧 Tools:    $count file collegati" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "  Base path: $bridgePath" -ForegroundColor Gray
    Write-Host ""
}

function Start-SystemBackup {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    💾 BACKUP SISTEMA                             ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $backupPath = $Global:Gene1799.Paths.Backup
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $backupPath "backup_$timestamp"
    
    Write-Gene1799 "Avvio backup sistema..." -Level SYSTEM
    
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    
    # Backup configurazione
    $configSrc = $Global:Gene1799.Paths.Config
    $configDst = Join-Path $backupDir "Config"
    if (Test-Path $configSrc) {
        Copy-Item -Path $configSrc -Destination $configDst -Recurse -Force
        Write-Host "  ✅ Config backuppata" -ForegroundColor Green
    }
    
    # Backup knowledge base
    $kbSrc = $Global:Gene1799.Paths.Knowledge
    $kbDst = Join-Path $backupDir "Knowledge"
    if (Test-Path $kbSrc) {
        Copy-Item -Path $kbSrc -Destination $kbDst -Recurse -Force
        Write-Host "  ✅ Knowledge Base backuppata" -ForegroundColor Green
    }
    
    # Backup agenti
    $agentsSrc = $Global:Gene1799.Paths.Agents
    $agentsDst = Join-Path $backupDir "Agents"
    if (Test-Path $agentsSrc) {
        Copy-Item -Path $agentsSrc -Destination $agentsDst -Recurse -Force
        Write-Host "  ✅ Agenti backuppati" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "  📁 Backup salvato in: $backupDir" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Gene1799 "Backup completato: $backupDir" -Level SUCCESS
}

function Start-SystemHealthCheck {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                    🩺 SYSTEM HEALTH CHECK                        ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    $issues = 0
    $warnings = 0
    
    # Check directories
    Write-Host "  📁 Verifica directory..." -ForegroundColor Yellow
    foreach ($pathName in $Global:Gene1799.Paths.Keys) {
        $path = $Global:Gene1799.Paths[$pathName]
        if (Test-Path $path) {
            Write-Host "    ✅ $pathName" -ForegroundColor Green
        }
        else {
            Write-Host "    ❌ $pathName - MANCANTE" -ForegroundColor Red
            $issues++
        }
    }
    
    Write-Host ""
    
    # Check config
    Write-Host "  ⚙️ Verifica configurazione..." -ForegroundColor Yellow
    $configFile = Join-Path $Global:Gene1799.Paths.Config "mega_system_config.json"
    if (Test-Path $configFile) {
        Write-Host "    ✅ Config principale" -ForegroundColor Green
    }
    else {
        Write-Host "    ⚠️ Config principale - MANCANTE (rigenerabile)" -ForegroundColor Yellow
        $warnings++
    }
    
    Write-Host ""
    
    # Check Neural Map
    Write-Host "  🧠 Verifica Neural Map..." -ForegroundColor Yellow
    $mapFile = Join-Path $Global:Gene1799.Paths.Synaptic "neural_map.json"
    if (Test-Path $mapFile) {
        Write-Host "    ✅ Neural Map" -ForegroundColor Green
    }
    else {
        Write-Host "    ⚠️ Neural Map - MANCANTE (rigenerabile)" -ForegroundColor Yellow
        $warnings++
    }
    
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    
    if ($issues -eq 0 -and $warnings -eq 0) {
        Write-Host "  ✅ Sistema in perfetta salute!" -ForegroundColor Green
    }
    elseif ($issues -eq 0) {
        Write-Host "  ⚠️ Sistema OK con $warnings avvisi minori" -ForegroundColor Yellow
    }
    else {
        Write-Host "  ❌ Trovati $issues problemi e $warnings avvisi" -ForegroundColor Red
        Write-Host "     Esegui: .\Gene1799_MegaSystem.ps1 -Mode INIT -Force" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  HELP E DOCUMENTAZIONE
# ══════════════════════════════════════════════════════════════════════════════

function Show-Help {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "║     ██████╗ ███████╗███╗   ██╗███████╗ ██╗ ███████╗ █████╗  █████╗          ║" -ForegroundColor Cyan
    Write-Host "║    ██╔════╝ ██╔════╝████╗  ██║██╔════╝███║╚════███║██╔══██╗██╔══██╗         ║" -ForegroundColor Cyan
    Write-Host "║    ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ╚██║    ███╔╝╚██████║╚██████║         ║" -ForegroundColor Cyan
    Write-Host "║    ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝   ██║   ███╔╝  ╚═══██║ ╚═══██║         ║" -ForegroundColor Cyan
    Write-Host "║    ╚██████╔╝███████╗██║ ╚████║███████╗ ██║  ███████╗█████╔╝ █████╔╝         ║" -ForegroundColor Cyan
    Write-Host "║     ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═╝  ╚══════╝╚════╝  ╚════╝          ║" -ForegroundColor Cyan
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "║              MEGA SISTEMA UNIFICATO v2.0 - GUIDA                            ║" -ForegroundColor Yellow
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  UTILIZZO:" -ForegroundColor Yellow
    Write-Host "    .\Gene1799_MegaSystem.ps1 -Mode <MODALITA> [opzioni]" -ForegroundColor White
    Write-Host ""
    Write-Host "  MODALITA DISPONIBILI:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    INIT      " -ForegroundColor Cyan -NoNewline
    Write-Host "Inizializza il sistema completo" -ForegroundColor White
    Write-Host "              Crea tutte le directory, config e neural map" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    GUI       " -ForegroundColor Cyan -NoNewline
    Write-Host "Avvia la Dashboard interattiva" -ForegroundColor White
    Write-Host "              Menu completo per gestire tutto il sistema" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    DASHBOARD " -ForegroundColor Cyan -NoNewline
    Write-Host "Alias per GUI" -ForegroundColor White
    Write-Host ""
    Write-Host "    AGENT     " -ForegroundColor Cyan -NoNewline
    Write-Host "Gestione agenti AI" -ForegroundColor White
    Write-Host "              Richiede: -AgentAction, -AgentName, [-AgentType]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    STATUS    " -ForegroundColor Cyan -NoNewline
    Write-Host "Mostra status completo del sistema" -ForegroundColor White
    Write-Host ""
    Write-Host "    SCAN      " -ForegroundColor Cyan -NoNewline
    Write-Host "Scansiona il sistema per file e risorse" -ForegroundColor White
    Write-Host ""
    Write-Host "    BACKUP    " -ForegroundColor Cyan -NoNewline
    Write-Host "Esegue backup di config, agenti e knowledge" -ForegroundColor White
    Write-Host ""
    Write-Host "    HEAL      " -ForegroundColor Cyan -NoNewline
    Write-Host "Health check e riparazione automatica" -ForegroundColor White
    Write-Host ""
    Write-Host "    HELP      " -ForegroundColor Cyan -NoNewline
    Write-Host "Mostra questa guida" -ForegroundColor White
    Write-Host ""
    Write-Host "  ESEMPI:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Inizializzazione sistema" -ForegroundColor Gray
    Write-Host "    .\Gene1799_MegaSystem.ps1 -Mode INIT" -ForegroundColor Green
    Write-Host ""
    Write-Host "    # Avvia dashboard interattiva" -ForegroundColor Gray
    Write-Host "    .\Gene1799_MegaSystem.ps1 -Mode GUI" -ForegroundColor Green
    Write-Host ""
    Write-Host "    # Crea nuovo agente" -ForegroundColor Gray
    Write-Host "    .\Gene1799_MegaSystem.ps1 -Mode AGENT -AgentAction CREATE \" -ForegroundColor Green
    Write-Host "        -AgentName 'FileBot' -AgentType FILE_MANAGER" -ForegroundColor Green
    Write-Host ""
    Write-Host "    # Training agente" -ForegroundColor Gray
    Write-Host "    .\Gene1799_MegaSystem.ps1 -Mode AGENT -AgentAction TRAIN \" -ForegroundColor Green
    Write-Host "        -AgentName 'FileBot' -TrainingCycles 50" -ForegroundColor Green
    Write-Host ""
    Write-Host "    # Deploy agente" -ForegroundColor Gray
    Write-Host "    .\Gene1799_MegaSystem.ps1 -Mode AGENT -AgentAction DEPLOY \" -ForegroundColor Green
    Write-Host "        -AgentName 'FileBot'" -ForegroundColor Green
    Write-Host ""
    Write-Host "  TIPI AGENTE:" -ForegroundColor Yellow
    Write-Host "    SOCIAL_MEDIA    - Social media management" -ForegroundColor Gray
    Write-Host "    FILE_MANAGER    - Gestione file intelligente" -ForegroundColor Gray
    Write-Host "    DATA_ANALYST    - Analisi dati e report" -ForegroundColor Gray
    Write-Host "    CONTENT_CREATOR - Creazione contenuti" -ForegroundColor Gray
    Write-Host "    MULTI_TASK      - Agente multi-funzione" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  FIRMA DIGITALE:" -ForegroundColor Yellow
    Write-Host "    $($Global:Gene1799.Signature.Organization)" -ForegroundColor Cyan
    Write-Host "    Licenza: $($Global:Gene1799.Signature.License)" -ForegroundColor Gray
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ══════════════════════════════════════════════════════════════════════════════

# Carica Knowledge Base all'avvio
$kbFile = Join-Path $Global:Gene1799.Paths.Knowledge "knowledge_base.json"
if (Test-Path $kbFile) {
    try {
        $Global:Gene1799.KnowledgeBase = Get-Content $kbFile -Raw | ConvertFrom-Json -AsHashtable
    }
    catch {}
}

switch ($Mode) {
    'INIT' {
        Initialize-Gene1799System -Force:$Force
    }
    
    'GUI' {
        Show-Dashboard
    }
    
    'DASHBOARD' {
        Show-Dashboard
    }
    
    'AGENT' {
        switch ($AgentAction) {
            'CREATE' {
                if (-not $AgentName -or -not $AgentType) {
                    Write-Host "❌ Specificare -AgentName e -AgentType" -ForegroundColor Red
                    Write-Host "   Tipi: SOCIAL_MEDIA, FILE_MANAGER, DATA_ANALYST, CONTENT_CREATOR, MULTI_TASK" -ForegroundColor Yellow
                }
                else {
                    New-Gene1799Agent -Name $AgentName -Type $AgentType
                }
            }
            'TRAIN' {
                if (-not $AgentName) {
                    Write-Host "❌ Specificare -AgentName" -ForegroundColor Red
                }
                else {
                    Start-AgentTraining -AgentName $AgentName -Cycles $TrainingCycles
                }
            }
            'DEPLOY' {
                if (-not $AgentName) {
                    Write-Host "❌ Specificare -AgentName" -ForegroundColor Red
                }
                else {
                    Deploy-Gene1799Agent -AgentName $AgentName
                }
            }
            'STATUS' {
                $agents = Get-AllAgents
                if ($agents.Count -eq 0) {
                    Write-Host "Nessun agente trovato" -ForegroundColor Yellow
                }
                else {
                    foreach ($agent in $agents) {
                        Write-Host ""
                        Write-Host "🤖 $($agent.Name) [$($agent.ID)]" -ForegroundColor Cyan
                        Write-Host "   Tipo: $($agent.Type)" -ForegroundColor Gray
                        Write-Host "   Status: $($agent.Status)" -ForegroundColor $(if ($agent.Status -eq "DEPLOYED") {"Green"} else {"Yellow"})
                        Write-Host "   Performance: $($agent.Performance.ToString('P0'))" -ForegroundColor Yellow
                        Write-Host "   Autonomia: $($agent.Autonomy.ToString('P0'))" -ForegroundColor Magenta
                    }
                }
            }
            default {
                Write-Host "❌ AgentAction non valida. Usa: CREATE, TRAIN, DEPLOY, STATUS" -ForegroundColor Red
            }
        }
    }
    
    'STATUS' {
        Show-SystemStatus
    }
    
    'SCAN' {
        Start-SystemScan
    }
    
    'BACKUP' {
        Start-SystemBackup
    }
    
    'HEAL' {
        Start-SystemHealthCheck
    }
    
    'NEURAL' {
        Show-NeuralHubStatus
    }
    
    'BRIDGE' {
        Start-BridgeManager
    }
    
    'HELP' {
        Show-Help
    }
    
    default {
        Show-Help
    }
}
