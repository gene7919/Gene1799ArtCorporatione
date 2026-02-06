#Requires -Version 7.0
<#
.SYNOPSIS
    GENE1799 AI Agent System - Sistema Agenti Autonomi
.DESCRIPTION
    Crea, gestisce e allena agenti AI specializzati con capacità di auto-apprendimento
    Specializzazioni: Social Media, File Manager, Data Analyst, Content Creator
.AUTHOR
    Gene1799 Art Corporation
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('CREATE','TRAIN','DEPLOY','STATUS','DELETE','EVOLVE')]
    [string]$Mode,
    
    [Parameter(Mandatory=$false)]
    [string]$AgentName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('SOCIAL_MEDIA','FILE_MANAGER','DATA_ANALYST','CONTENT_CREATOR','MULTI_TASK')]
    [string]$AgentType,
    
    [Parameter(Mandatory=$false)]
    [int]$TrainingCycles = 10
)

# Importa il Core
. "D:\Gene1799\Explorer\gene1799_ai_integration_core.ps1" -Mode START

# ═══════════════════════════════════════════════════════════════════
#  DEFINIZIONI AGENTI SPECIALIZZATI
# ═══════════════════════════════════════════════════════════════════

$Global:AgentTemplates = @{
    SOCIAL_MEDIA = @{
        Name = "Social Media Manager"
        Description = "Gestisce profili social, crea contenuti, analizza engagement"
        Capabilities = @(
            "PostContent",
            "SchedulePosts",
            "AnalyzeEngagement",
            "RespondComments",
            "TrendAnalysis",
            "HashtagOptimization",
            "AudienceGrowth"
        )
        Platforms = @("Facebook", "Instagram", "Twitter", "LinkedIn")
        LearningFocus = @("BestPostingTimes", "ContentTypes", "AudiencePreferences")
        AutomationLevel = 0.7
    }
    
    FILE_MANAGER = @{
        Name = "Intelligent File Manager"
        Description = "Organizza, classifica e gestisce file automaticamente"
        Capabilities = @(
            "AutoOrganize",
            "SmartTagging",
            "DuplicateDetection",
            "BackupManagement",
            "FileClassification",
            "StorageOptimization",
            "SearchOptimization"
        )
        SupportedTypes = @("Documents", "Images", "Videos", "Audio", "Archives")
        LearningFocus = @("OrganizationPatterns", "UserPreferences", "FileImportance")
        AutomationLevel = 0.9
    }
    
    DATA_ANALYST = @{
        Name = "Data Analysis Agent"
        Description = "Analizza dati, crea report e identifica pattern"
        Capabilities = @(
            "DataCollection",
            "PatternRecognition",
            "ReportGeneration",
            "PredictiveAnalysis",
            "Visualization",
            "TrendForecasting",
            "AnomalyDetection"
        )
        DataSources = @("Files", "Databases", "APIs", "WebScraping")
        LearningFocus = @("DataPatterns", "PredictionAccuracy", "InsightGeneration")
        AutomationLevel = 0.8
    }
    
    CONTENT_CREATOR = @{
        Name = "Creative Content Generator"
        Description = "Crea contenuti originali: testi, immagini, video"
        Capabilities = @(
            "TextGeneration",
            "ImageCreation",
            "VideoEditing",
            "SEOOptimization",
            "BrandConsistency",
            "MultilingualContent",
            "ContentAdaptation"
        )
        ContentTypes = @("BlogPosts", "SocialPosts", "Graphics", "Videos", "Presentations")
        LearningFocus = @("WritingStyle", "VisualPreferences", "AudienceResponse")
        AutomationLevel = 0.6
    }
}

# ═══════════════════════════════════════════════════════════════════
#  CLASSE AGENTE AI
# ═══════════════════════════════════════════════════════════════════

class Gene1799Agent {
    [string]$ID
    [string]$Name
    [string]$Type
    [hashtable]$Capabilities
    [hashtable]$Skills
    [int]$Level
    [double]$Autonomy
    [datetime]$Created
    [datetime]$LastActive
    [int]$ActionsCount
    [string]$Status
    [hashtable]$Memory
    [hashtable]$Goals
    [double]$Performance
    
    Gene1799Agent([string]$name, [string]$type, [hashtable]$template) {
        $this.ID = [guid]::NewGuid().ToString().Substring(0,8)
        $this.Name = $name
        $this.Type = $type
        $this.Capabilities = $template
        $this.Skills = @{}
        $this.Level = 1
        $this.Autonomy = 0.3
        $this.Created = Get-Date
        $this.LastActive = Get-Date
        $this.ActionsCount = 0
        $this.Status = "CREATED"
        $this.Memory = @{
            ShortTerm = @()
            LongTerm = @()
            Experiences = @()
        }
        $this.Goals = @{
            Current = @()
            Completed = @()
        }
        $this.Performance = 0.5
        
        # Inizializza skills di base
        foreach ($cap in $template.Capabilities) {
            $this.Skills[$cap] = @{
                Level = 1
                Experience = 0
                SuccessRate = 0.0
                LastUsed = $null
            }
        }
    }
    
    [void] Learn([string]$skill, [bool]$success) {
        if ($this.Skills.ContainsKey($skill)) {
            $this.Skills[$skill].Experience++
            $this.Skills[$skill].LastUsed = Get-Date
            
            if ($success) {
                $this.Skills[$skill].SuccessRate = 
                    (($this.Skills[$skill].SuccessRate * ($this.Skills[$skill].Experience - 1)) + 1) / 
                    $this.Skills[$skill].Experience
                
                # Level up ogni 10 successi
                if ($this.Skills[$skill].Experience % 10 -eq 0) {
                    $this.Skills[$skill].Level++
                    $Global:Gene1799Core.WriteLog.Invoke(
                        "🎓 $($this.Name) - $skill ora a Level $($this.Skills[$skill].Level)!", 
                        "SUCCESS"
                    )
                }
            }
            else {
                $this.Skills[$skill].SuccessRate = 
                    (($this.Skills[$skill].SuccessRate * ($this.Skills[$skill].Experience - 1))) / 
                    $this.Skills[$skill].Experience
            }
            
            # Aggiorna performance generale
            $this.UpdatePerformance()
        }
    }
    
    [void] UpdatePerformance() {
        $totalSuccess = 0
        $totalSkills = 0
        
        foreach ($skill in $this.Skills.Keys) {
            $totalSuccess += $this.Skills[$skill].SuccessRate
            $totalSkills++
        }
        
        if ($totalSkills -gt 0) {
            $this.Performance = $totalSuccess / $totalSkills
            
            # Aumenta autonomia basata su performance
            if ($this.Performance -gt 0.8) {
                $this.Autonomy = [math]::Min($this.Autonomy + 0.05, 0.95)
            }
        }
    }
    
    [void] AddMemory([string]$type, [object]$data) {
        $memory = @{
            Timestamp = Get-Date
            Type = $type
            Data = $data
        }
        
        $this.Memory.ShortTerm += $memory
        
        # Consolida memoria dopo 100 entry
        if ($this.Memory.ShortTerm.Count -gt 100) {
            $this.ConsolidateMemory()
        }
    }
    
    [void] ConsolidateMemory() {
        # Sposta memoria importante da short-term a long-term
        $important = $this.Memory.ShortTerm | 
            Where-Object {$_.Data.Success -eq $true} | 
            Select-Object -Last 20
        
        $this.Memory.LongTerm += $important
        $this.Memory.ShortTerm = $this.Memory.ShortTerm | Select-Object -Last 20
    }
    
    [hashtable] MakeDecision([string]$situation, [array]$options) {
        # Sistema decisionale basato su esperienza
        $bestOption = $null
        $bestScore = 0
        
        foreach ($option in $options) {
            $score = $this.Autonomy
            
            # Cerca in memoria esperienze simili
            $similar = $this.Memory.LongTerm | 
                Where-Object {$_.Type -eq $situation}
            
            if ($similar) {
                $successRate = ($similar | Where-Object {$_.Data.Success}).Count / $similar.Count
                $score += $successRate * 0.5
            }
            
            # Consulta knowledge base globale
            $bestPractice = $Global:Gene1799Core.GetBestPractice.Invoke($option, $situation)
            if ($bestPractice.Found) {
                $score += $bestPractice.Confidence * 0.3
            }
            
            if ($score -gt $bestScore) {
                $bestScore = $score
                $bestOption = $option
            }
        }
        
        return @{
            Choice = $bestOption
            Confidence = $bestScore
            RequiresApproval = ($bestScore -lt 0.7)
        }
    }
    
    [void] SelfCorrect([string]$error) {
        $Global:Gene1799Core.WriteLog.Invoke(
            "🔧 $($this.Name) - Auto-correzione per: $error", 
            "WARNING"
        )
        
        $correction = $Global:Gene1799Core.SelfCorrection.Invoke($this.Name, $error)
        
        if ($correction) {
            $this.AddMemory("ErrorCorrection", @{
                Error = $error
                Correction = $correction
                Timestamp = Get-Date
            })
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
#  FUNZIONI GESTIONE AGENTI
# ═══════════════════════════════════════════════════════════════════

function New-Gene1799Agent {
    param(
        [string]$Name,
        [string]$Type
    )
    
    $Global:Gene1799Core.WriteLog.Invoke("🤖 Creazione agente: $Name ($Type)", "INFO")
    
    if (-not $Global:AgentTemplates.ContainsKey($Type)) {
        $Global:Gene1799Core.WriteLog.Invoke("❌ Tipo agente non valido: $Type", "ERROR")
        return $null
    }
    
    $template = $Global:AgentTemplates[$Type]
    $agent = [Gene1799Agent]::new($Name, $Type, $template)
    
    # Salva configurazione agente
    $agentPath = Join-Path $Global:Gene1799Config.AgentsPath "$($Type)\$($agent.ID)_$Name"
    New-Item -Path $agentPath -ItemType Directory -Force | Out-Null
    
    $agentConfig = @{
        ID = $agent.ID
        Name = $agent.Name
        Type = $agent.Type
        Created = $agent.Created
        ConfigPath = $agentPath
    }
    
    $configFile = Join-Path $agentPath "agent_config.json"
    $agentConfig | ConvertTo-Json -Depth 5 | Set-Content $configFile
    
    # Salva stato agente
    Save-AgentState -Agent $agent
    
    $Global:Gene1799Core.WriteLog.Invoke(
        "✅ Agente $Name creato con ID: $($agent.ID)", 
        "SUCCESS"
    )
    
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║      AGENTE CREATO CON SUCCESSO       ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "`nID: $($agent.ID)" -ForegroundColor Cyan
    Write-Host "Nome: $($agent.Name)" -ForegroundColor Cyan
    Write-Host "Tipo: $($agent.Type)" -ForegroundColor Cyan
    Write-Host "Capabilities: $($template.Capabilities.Count)" -ForegroundColor Yellow
    Write-Host "`nCapacità:" -ForegroundColor Magenta
    foreach ($cap in $template.Capabilities) {
        Write-Host "  • $cap" -ForegroundColor Gray
    }
    
    return $agent
}

function Save-AgentState {
    param([Gene1799Agent]$Agent)
    
    $agentPath = Join-Path $Global:Gene1799Config.AgentsPath "$($Agent.Type)\$($Agent.ID)_$($Agent.Name)"
    $stateFile = Join-Path $agentPath "agent_state.json"
    
    $state = @{
        ID = $Agent.ID
        Name = $Agent.Name
        Type = $Agent.Type
        Level = $Agent.Level
        Autonomy = $Agent.Autonomy
        Performance = $Agent.Performance
        ActionsCount = $Agent.ActionsCount
        Status = $Agent.Status
        Skills = $Agent.Skills
        Memory = $Agent.Memory
        Goals = $Agent.Goals
        LastSaved = Get-Date
    }
    
    $state | ConvertTo-Json -Depth 10 | Set-Content $stateFile
}

function Start-AgentTraining {
    param(
        [Gene1799Agent]$Agent,
        [int]$Cycles = 10
    )
    
    $Global:Gene1799Core.WriteLog.Invoke(
        "🎓 Inizio training $($Agent.Name) - $Cycles cicli", 
        "LEARNING"
    )
    
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║       TRAINING IN CORSO...            ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta
    
    $skills = $Agent.Skills.Keys | Get-Random -Count ([math]::Min(3, $Agent.Skills.Count))
    
    for ($i = 1; $i -le $Cycles; $i++) {
        Write-Host "`n🔄 Ciclo $i/$Cycles" -ForegroundColor Cyan
        
        foreach ($skill in $skills) {
            Write-Host "  📚 Training: $skill" -ForegroundColor Yellow
            
            # Simula training con probabilità di successo basata su livello
            $successProbability = 0.5 + ($Agent.Skills[$skill].Level * 0.05)
            $success = (Get-Random -Minimum 0.0 -Maximum 1.0) -lt $successProbability
            
            # Agente impara
            $Agent.Learn($skill, $success)
            $Agent.ActionsCount++
            
            # Registra esperienza nel core
            $Global:Gene1799Core.AddExperience.Invoke(
                $Agent.Name,
                $skill,
                "Training",
                $success,
                $(if ($success) {"Success"} else {"Failed"}),
                @{
                    Cycle = $i
                    Level = $Agent.Skills[$skill].Level
                }
            )
            
            $statusIcon = if ($success) {"✅"} else {"❌"}
            $statusText = if ($success) {"SUCCESS"} else {"FAILED"}
            Write-Host "    $statusIcon $statusText - Success Rate: $($Agent.Skills[$skill].SuccessRate.ToString('P2'))" -ForegroundColor $(if ($success) {"Green"} else {"Red"})
            
            Start-Sleep -Milliseconds 300
        }
        
        Write-Host "  📊 Performance: $($Agent.Performance.ToString('P2'))" -ForegroundColor Cyan
        Write-Host "  🎯 Autonomia: $($Agent.Autonomy.ToString('P2'))" -ForegroundColor Cyan
    }
    
    $Agent.Status = "TRAINED"
    Save-AgentState -Agent $Agent
    
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║       TRAINING COMPLETATO!            ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "`n📊 Risultati Finali:" -ForegroundColor Magenta
    Write-Host "Level: $($Agent.Level)" -ForegroundColor Cyan
    Write-Host "Performance: $($Agent.Performance.ToString('P2'))" -ForegroundColor Cyan
    Write-Host "Autonomia: $($Agent.Autonomy.ToString('P2'))" -ForegroundColor Cyan
    Write-Host "Azioni eseguite: $($Agent.ActionsCount)" -ForegroundColor Cyan
    
    $Global:Gene1799Core.WriteLog.Invoke(
        "✅ Training completato: $($Agent.Name) - Performance: $($Agent.Performance.ToString('P2'))", 
        "SUCCESS"
    )
}

function Deploy-Gene1799Agent {
    param([Gene1799Agent]$Agent)
    
    $Global:Gene1799Core.WriteLog.Invoke(
        "🚀 Deploy agente: $($Agent.Name)", 
        "SUCCESS"
    )
    
    $Agent.Status = "DEPLOYED"
    $Agent.LastActive = Get-Date
    $Global:ActiveAgents += $Agent
    
    Save-AgentState -Agent $Agent
    
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║      AGENTE DEPLOYED!                 ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "`n🤖 $($Agent.Name) è ora attivo e operativo!" -ForegroundColor Cyan
    Write-Host "Autonomia: $($Agent.Autonomy.ToString('P2'))" -ForegroundColor Yellow
    Write-Host "Performance: $($Agent.Performance.ToString('P2'))" -ForegroundColor Yellow
    
    # Avvia ciclo di lavoro autonomo
    Start-AutonomousWork -Agent $Agent
}

function Start-AutonomousWork {
    param([Gene1799Agent]$Agent)
    
    Write-Host "`n🔄 Modalità Autonoma Attivata per $($Agent.Name)" -ForegroundColor Magenta
    Write-Host "L'agente ora lavorerà in modo autonomo basandosi su:" -ForegroundColor Gray
    Write-Host "  • Esperienza accumulata" -ForegroundColor Gray
    Write-Host "  • Pattern appresi" -ForegroundColor Gray
    Write-Host "  • Knowledge base condivisa" -ForegroundColor Gray
    Write-Host "  • Auto-correzione degli errori" -ForegroundColor Gray
}

function Get-AllAgents {
    $agents = @()
    
    foreach ($type in $Global:AgentTemplates.Keys) {
        $typePath = Join-Path $Global:Gene1799Config.AgentsPath $type
        
        if (Test-Path $typePath) {
            $agentDirs = Get-ChildItem -Path $typePath -Directory
            
            foreach ($dir in $agentDirs) {
                $stateFile = Join-Path $dir.FullName "agent_state.json"
                if (Test-Path $stateFile) {
                    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
                    $agents += $state
                }
            }
        }
    }
    
    return $agents
}

function Show-AgentStatus {
    $agents = Get-AllAgents
    
    if ($agents.Count -eq 0) {
        Write-Host "`n⚠ Nessun agente trovato. Crea un nuovo agente con -Mode CREATE" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              STATUS AGENTI GENE1799                       ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "`nAgenti Totali: $($agents.Count)" -ForegroundColor Magenta
    
    foreach ($agent in $agents) {
        Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "🤖 $($agent.Name) [$($agent.ID)]" -ForegroundColor Cyan
        Write-Host "   Tipo: $($agent.Type)" -ForegroundColor Gray
        Write-Host "   Status: $($agent.Status)" -ForegroundColor $(if ($agent.Status -eq "DEPLOYED") {"Green"} else {"Yellow"})
        Write-Host "   Level: $($agent.Level)" -ForegroundColor Yellow
        Write-Host "   Performance: $($agent.Performance.ToString('P2'))" -ForegroundColor $(if ($agent.Performance -gt 0.7) {"Green"} else {"Yellow"})
        Write-Host "   Autonomia: $($agent.Autonomy.ToString('P2'))" -ForegroundColor Magenta
        Write-Host "   Azioni: $($agent.ActionsCount)" -ForegroundColor Gray
        
        if ($agent.Skills) {
            Write-Host "   Skills Top 3:" -ForegroundColor Cyan
            $topSkills = $agent.Skills.PSObject.Properties | 
                Sort-Object {$_.Value.SuccessRate} -Descending | 
                Select-Object -First 3
            
            foreach ($skill in $topSkills) {
                Write-Host "     • $($skill.Name): Lvl $($skill.Value.Level) ($($skill.Value.SuccessRate.ToString('P0')))" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
}

function Start-AgentEvolutionCycle {
    $agents = Get-AllAgents
    
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║     CICLO DI EVOLUZIONE AGENTI        ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta
    
    foreach ($agent in $agents) {
        if ($agent.Performance -gt 0.8 -and $agent.ActionsCount -gt 50) {
            Write-Host "`n⬆ $($agent.Name) qualificato per evoluzione!" -ForegroundColor Green
            Write-Host "  Performance: $($agent.Performance.ToString('P2'))" -ForegroundColor Cyan
            Write-Host "  Esperienza: $($agent.ActionsCount) azioni" -ForegroundColor Cyan
            
            # Evoluzione
            $newLevel = $agent.Level + 1
            $newAutonomy = [math]::Min($agent.Autonomy + 0.1, 0.95)
            
            Write-Host "  Level: $($agent.Level) → $newLevel" -ForegroundColor Yellow
            Write-Host "  Autonomia: $($agent.Autonomy.ToString('P2')) → $($newAutonomy.ToString('P2'))" -ForegroundColor Yellow
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════

Clear-Host

switch ($Mode) {
    'CREATE' {
        if (-not $AgentName -or -not $AgentType) {
            Write-Host "❌ Specifica -AgentName e -AgentType" -ForegroundColor Red
            Write-Host "`nTipi disponibili:" -ForegroundColor Yellow
            foreach ($type in $Global:AgentTemplates.Keys) {
                Write-Host "  • $type - $($Global:AgentTemplates[$type].Description)" -ForegroundColor Gray
            }
            return
        }
        
        $agent = New-Gene1799Agent -Name $AgentName -Type $AgentType
    }
    
    'TRAIN' {
        if (-not $AgentName) {
            Write-Host "❌ Specifica -AgentName da trainare" -ForegroundColor Red
            return
        }
        
        # Carica agente esistente
        $agents = Get-AllAgents
        $agentData = $agents | Where-Object {$_.Name -eq $AgentName} | Select-Object -First 1
        
        if (-not $agentData) {
            Write-Host "❌ Agente '$AgentName' non trovato" -ForegroundColor Red
            return
        }
        
        # Ricrea oggetto agente
        $template = $Global:AgentTemplates[$agentData.Type]
        $agent = [Gene1799Agent]::new($agentData.Name, $agentData.Type, $template)
        $agent.ID = $agentData.ID
        $agent.Level = $agentData.Level
        $agent.Autonomy = $agentData.Autonomy
        $agent.Performance = $agentData.Performance
        $agent.ActionsCount = $agentData.ActionsCount
        $agent.Skills = $agentData.Skills
        
        Start-AgentTraining -Agent $agent -Cycles $TrainingCycles
    }
    
    'DEPLOY' {
        if (-not $AgentName) {
            Write-Host "❌ Specifica -AgentName da deployare" -ForegroundColor Red
            return
        }
        
        $agents = Get-AllAgents
        $agentData = $agents | Where-Object {$_.Name -eq $AgentName} | Select-Object -First 1
        
        if (-not $agentData) {
            Write-Host "❌ Agente '$AgentName' non trovato" -ForegroundColor Red
            return
        }
        
        $template = $Global:AgentTemplates[$agentData.Type]
        $agent = [Gene1799Agent]::new($agentData.Name, $agentData.Type, $template)
        $agent.ID = $agentData.ID
        $agent.Level = $agentData.Level
        $agent.Autonomy = $agentData.Autonomy
        $agent.Performance = $agentData.Performance
        $agent.Skills = $agentData.Skills
        
        Deploy-Gene1799Agent -Agent $agent
    }
    
    'STATUS' {
        Show-AgentStatus
    }
    
    'EVOLVE' {
        Start-AgentEvolutionCycle
    }
    
    'DELETE' {
        if (-not $AgentName) {
            Write-Host "❌ Specifica -AgentName da eliminare" -ForegroundColor Red
            return
        }
        
        $agents = Get-AllAgents
        $agentData = $agents | Where-Object {$_.Name -eq $AgentName} | Select-Object -First 1
        
        if ($agentData) {
            $agentPath = Join-Path $Global:Gene1799Config.AgentsPath "$($agentData.Type)\$($agentData.ID)_$($agentData.Name)"
            Remove-Item -Path $agentPath -Recurse -Force
            Write-Host "✅ Agente $AgentName eliminato" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Agente non trovato" -ForegroundColor Red
        }
    }
}
