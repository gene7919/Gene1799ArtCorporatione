#Requires -Version 7.0
<#
.SYNOPSIS
    GENE1799 AI Integration Core - Sistema Centrale Intelligente
.DESCRIPTION
    Core centrale per gestione agenti AI autonomi con auto-apprendimento
    Gestisce la comunicazione, l'apprendimento e l'evoluzione degli agenti
.AUTHOR
    Gene1799 Art Corporation
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('INIT','START','STOP','STATUS','LEARN','EVOLVE')]
    [string]$Mode = 'START',
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "D:\Gene1799\Explorer\Config"
)

# ═══════════════════════════════════════════════════════════════════
#  CONFIGURAZIONE GLOBALE
# ═══════════════════════════════════════════════════════════════════

$Global:Gene1799Config = @{
    Version = "1.0.0"
    CorePath = "D:\Gene1799\Explorer"
    AgentsPath = "D:\Gene1799\Explorer\Agents"
    DataPath = "D:\Gene1799\Explorer\Data"
    LogsPath = "D:\Gene1799\Explorer\Logs"
    KnowledgePath = "D:\Gene1799\Explorer\Knowledge"
    ModelsPath = "D:\Gene1799\Explorer\Models"
    MaxAgents = 10
    LearningRate = 0.01
    AutoSaveInterval = 300 # secondi
}

$Global:ActiveAgents = @()
$Global:KnowledgeBase = @{}
$Global:PerformanceMetrics = @{}

# ═══════════════════════════════════════════════════════════════════
#  FUNZIONI DI BASE
# ═══════════════════════════════════════════════════════════════════

function Write-Gene1799Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR','LEARNING')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $Global:Gene1799Config.LogsPath "core_$(Get-Date -Format 'yyyyMMdd').log"
    
    $colors = @{
        'INFO' = 'Cyan'
        'SUCCESS' = 'Green'
        'WARNING' = 'Yellow'
        'ERROR' = 'Red'
        'LEARNING' = 'Magenta'
    }
    
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colors[$Level]
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Initialize-Gene1799Structure {
    Write-Gene1799Log "🔧 Inizializzazione struttura Gene1799..." -Level INFO
    
    $directories = @(
        $Global:Gene1799Config.CorePath,
        $Global:Gene1799Config.AgentsPath,
        $Global:Gene1799Config.DataPath,
        $Global:Gene1799Config.LogsPath,
        $Global:Gene1799Config.KnowledgePath,
        $Global:Gene1799Config.ModelsPath,
        "$($Global:Gene1799Config.AgentsPath)\SocialMedia",
        "$($Global:Gene1799Config.AgentsPath)\FileManager",
        "$($Global:Gene1799Config.AgentsPath)\DataAnalyst",
        "$($Global:Gene1799Config.AgentsPath)\ContentCreator",
        "$($Global:Gene1799Config.KnowledgePath)\Experiences",
        "$($Global:Gene1799Config.KnowledgePath)\Patterns",
        "$($Global:Gene1799Config.KnowledgePath)\ErrorCorrections"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Gene1799Log "✓ Creata directory: $dir" -Level SUCCESS
        }
    }
    
    # Crea file di configurazione base
    $configFile = Join-Path $Global:Gene1799Config.CorePath "core_config.json"
    if (-not (Test-Path $configFile)) {
        $Global:Gene1799Config | ConvertTo-Json -Depth 5 | Set-Content $configFile
        Write-Gene1799Log "✓ Configurazione salvata" -Level SUCCESS
    }
    
    # Inizializza knowledge base
    Initialize-KnowledgeBase
    
    Write-Gene1799Log "✅ Struttura inizializzata con successo!" -Level SUCCESS
}

function Initialize-KnowledgeBase {
    Write-Gene1799Log "🧠 Inizializzazione Knowledge Base..." -Level INFO
    
    $Global:KnowledgeBase = @{
        Experiences = @()
        Patterns = @()
        ErrorCorrections = @()
        SuccessRates = @{}
        BestPractices = @()
        LastUpdate = Get-Date
    }
    
    $kbFile = Join-Path $Global:Gene1799Config.KnowledgePath "knowledge_base.json"
    if (Test-Path $kbFile) {
        try {
            $loaded = Get-Content $kbFile -Raw | ConvertFrom-Json
            $Global:KnowledgeBase = $loaded
            Write-Gene1799Log "✓ Knowledge Base caricata: $($loaded.Experiences.Count) esperienze" -Level SUCCESS
        }
        catch {
            Write-Gene1799Log "⚠ Errore caricamento KB, creo nuova" -Level WARNING
        }
    }
    else {
        Save-KnowledgeBase
    }
}

function Save-KnowledgeBase {
    $kbFile = Join-Path $Global:Gene1799Config.KnowledgePath "knowledge_base.json"
    $Global:KnowledgeBase.LastUpdate = Get-Date
    $Global:KnowledgeBase | ConvertTo-Json -Depth 10 | Set-Content $kbFile
    Write-Gene1799Log "💾 Knowledge Base salvata" -Level INFO
}

# ═══════════════════════════════════════════════════════════════════
#  SISTEMA DI APPRENDIMENTO
# ═══════════════════════════════════════════════════════════════════

function Add-Experience {
    param(
        [string]$AgentName,
        [string]$Action,
        [string]$Context,
        [bool]$Success,
        [string]$Result,
        [hashtable]$Metadata = @{}
    )
    
    $experience = @{
        Timestamp = Get-Date
        AgentName = $AgentName
        Action = $Action
        Context = $Context
        Success = $Success
        Result = $Result
        Metadata = $Metadata
        ID = [guid]::NewGuid().ToString()
    }
    
    $Global:KnowledgeBase.Experiences += $experience
    
    # Aggiorna metriche di successo
    $key = "$AgentName-$Action"
    if (-not $Global:KnowledgeBase.SuccessRates.ContainsKey($key)) {
        $Global:KnowledgeBase.SuccessRates[$key] = @{
            Total = 0
            Success = 0
            Rate = 0.0
        }
    }
    
    $Global:KnowledgeBase.SuccessRates[$key].Total++
    if ($Success) {
        $Global:KnowledgeBase.SuccessRates[$key].Success++
    }
    $Global:KnowledgeBase.SuccessRates[$key].Rate = 
        $Global:KnowledgeBase.SuccessRates[$key].Success / 
        $Global:KnowledgeBase.SuccessRates[$key].Total
    
    Write-Gene1799Log "📚 Esperienza registrata: $Action ($Success) - Success Rate: $($Global:KnowledgeBase.SuccessRates[$key].Rate.ToString('P2'))" -Level LEARNING
    
    # Analizza pattern se abbastanza esperienze
    if ($Global:KnowledgeBase.Experiences.Count % 10 -eq 0) {
        Analyze-Patterns
    }
    
    Save-KnowledgeBase
}

function Analyze-Patterns {
    Write-Gene1799Log "🔍 Analisi pattern in corso..." -Level LEARNING
    
    # Raggruppa esperienze per azione
    $grouped = $Global:KnowledgeBase.Experiences | Group-Object -Property Action
    
    foreach ($group in $grouped) {
        $successRate = ($group.Group | Where-Object {$_.Success}).Count / $group.Count
        
        if ($successRate -gt 0.8) {
            # Pattern di successo identificato
            $pattern = @{
                Action = $group.Name
                SuccessRate = $successRate
                BestContext = ($group.Group | Where-Object {$_.Success} | Select-Object -First 1).Context
                Discovered = Get-Date
            }
            
            # Aggiungi solo se non esiste già
            if (-not ($Global:KnowledgeBase.Patterns | Where-Object {$_.Action -eq $pattern.Action})) {
                $Global:KnowledgeBase.Patterns += $pattern
                Write-Gene1799Log "✨ Nuovo pattern scoperto: $($group.Name) (Success: $($successRate.ToString('P2')))" -Level LEARNING
            }
        }
        elseif ($successRate -lt 0.3) {
            # Pattern problematico - crea correzione
            $correction = @{
                Action = $group.Name
                FailureRate = 1 - $successRate
                CommonError = ($group.Group | Where-Object {-not $_.Success} | Select-Object -First 1).Result
                Timestamp = Get-Date
            }
            
            if (-not ($Global:KnowledgeBase.ErrorCorrections | Where-Object {$_.Action -eq $correction.Action})) {
                $Global:KnowledgeBase.ErrorCorrections += $correction
                Write-Gene1799Log "⚠ Pattern problematico: $($group.Name) (Failure: $((1-$successRate).ToString('P2')))" -Level WARNING
            }
        }
    }
    
    Save-KnowledgeBase
}

function Get-BestPractice {
    param(
        [string]$Action,
        [string]$Context
    )
    
    # Cerca nella knowledge base la migliore pratica per questa azione
    $relevantExperiences = $Global:KnowledgeBase.Experiences | 
        Where-Object {$_.Action -eq $Action -and $_.Success -eq $true} |
        Sort-Object -Property Timestamp -Descending |
        Select-Object -First 5
    
    if ($relevantExperiences) {
        $bestPractice = $relevantExperiences | Select-Object -First 1
        return @{
            Found = $true
            Practice = $bestPractice
            Confidence = ($relevantExperiences.Count / 5.0)
        }
    }
    
    return @{Found = $false}
}

function Invoke-SelfCorrection {
    param(
        [string]$AgentName,
        [string]$Error
    )
    
    Write-Gene1799Log "🔧 Auto-correzione avviata per: $AgentName" -Level WARNING
    
    # Cerca pattern di errore simili
    $similarErrors = $Global:KnowledgeBase.ErrorCorrections | 
        Where-Object {$_.CommonError -like "*$Error*"}
    
    if ($similarErrors) {
        Write-Gene1799Log "✓ Trovate $($similarErrors.Count) correzioni simili" -Level INFO
        return $similarErrors[0]
    }
    
    # Crea nuova strategia di correzione
    $correction = @{
        Error = $Error
        AttemptedFixes = @()
        Timestamp = Get-Date
    }
    
    return $correction
}

# ═══════════════════════════════════════════════════════════════════
#  GESTIONE AGENTI
# ═══════════════════════════════════════════════════════════════════

function Get-AgentStatus {
    Write-Gene1799Log "📊 Status Agenti Attivi: $($Global:ActiveAgents.Count)" -Level INFO
    
    foreach ($agent in $Global:ActiveAgents) {
        $key = "$($agent.Name)-*"
        $successRates = $Global:KnowledgeBase.SuccessRates.Keys | Where-Object {$_ -like $key}
        
        Write-Host "`n🤖 $($agent.Name) [$($agent.Type)]" -ForegroundColor Cyan
        Write-Host "   Status: $($agent.Status)" -ForegroundColor Green
        Write-Host "   Azioni eseguite: $($agent.ActionsCount)" -ForegroundColor Yellow
        
        if ($successRates) {
            foreach ($sr in $successRates) {
                $rate = $Global:KnowledgeBase.SuccessRates[$sr]
                Write-Host "   $($sr.Replace($agent.Name + '-','')): $($rate.Rate.ToString('P2')) ($($rate.Success)/$($rate.Total))" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host "`n📚 Knowledge Base Stats:" -ForegroundColor Magenta
    Write-Host "   Esperienze totali: $($Global:KnowledgeBase.Experiences.Count)" -ForegroundColor Gray
    Write-Host "   Pattern scoperti: $($Global:KnowledgeBase.Patterns.Count)" -ForegroundColor Gray
    Write-Host "   Correzioni attive: $($Global:KnowledgeBase.ErrorCorrections.Count)" -ForegroundColor Gray
}

function Start-AgentEvolution {
    Write-Gene1799Log "🧬 Avvio evoluzione agenti..." -Level LEARNING
    
    foreach ($agent in $Global:ActiveAgents) {
        $agentKey = "$($agent.Name)-*"
        $agentExperiences = $Global:KnowledgeBase.Experiences | 
            Where-Object {$_.AgentName -eq $agent.Name}
        
        if ($agentExperiences.Count -gt 20) {
            $successRate = ($agentExperiences | Where-Object {$_.Success}).Count / $agentExperiences.Count
            
            # Evoluzione basata su performance
            if ($successRate -gt 0.85) {
                $agent.Level = [math]::Min($agent.Level + 1, 10)
                $agent.Autonomy = [math]::Min($agent.Autonomy + 0.1, 1.0)
                Write-Gene1799Log "⬆ $($agent.Name) evoluto a Level $($agent.Level)!" -Level SUCCESS
            }
            elseif ($successRate -lt 0.5) {
                Write-Gene1799Log "📉 $($agent.Name) richiede training aggiuntivo (Success: $($successRate.ToString('P2')))" -Level WARNING
                # Trigger re-training
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════

function Start-Gene1799Core {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       GENE1799 AI INTEGRATION CORE - v1.0.0              ║" -ForegroundColor Cyan
    Write-Host "║       Sistema Intelligente Auto-Apprendente               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    switch ($Mode) {
        'INIT' {
            Write-Gene1799Log "🚀 Modalità: INIZIALIZZAZIONE" -Level INFO
            Initialize-Gene1799Structure
            Write-Host "`n✅ Sistema inizializzato! Esegui con -Mode START per avviare." -ForegroundColor Green
        }
        
        'START' {
            Write-Gene1799Log "🚀 Modalità: START CORE" -Level INFO
            Initialize-KnowledgeBase
            Write-Gene1799Log "✅ Core avviato e pronto!" -Level SUCCESS
            Write-Host "`n📝 Usa gli altri script per creare e gestire gli agenti." -ForegroundColor Yellow
        }
        
        'STATUS' {
            Initialize-KnowledgeBase
            Get-AgentStatus
        }
        
        'LEARN' {
            Initialize-KnowledgeBase
            Analyze-Patterns
            Write-Gene1799Log "✅ Analisi completata!" -Level SUCCESS
        }
        
        'EVOLVE' {
            Initialize-KnowledgeBase
            Start-AgentEvolution
            Save-KnowledgeBase
            Write-Gene1799Log "✅ Evoluzione completata!" -Level SUCCESS
        }
        
        'STOP' {
            Write-Gene1799Log "🛑 Arresto Core..." -Level WARNING
            Save-KnowledgeBase
            Write-Gene1799Log "✅ Core arrestato in sicurezza" -Level SUCCESS
        }
    }
}

# Esporta funzioni per uso da altri script
$Global:Gene1799Core = @{
    AddExperience = ${function:Add-Experience}
    GetBestPractice = ${function:Get-BestPractice}
    SelfCorrection = ${function:Invoke-SelfCorrection}
    SaveKnowledge = ${function:Save-KnowledgeBase}
    WriteLog = ${function:Write-Gene1799Log}
}

# Avvia il core
Start-Gene1799Core
