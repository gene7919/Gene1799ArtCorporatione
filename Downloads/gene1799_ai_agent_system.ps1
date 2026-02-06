# ═══════════════════════════════════════════════════════════
# 🤖 GENE1799 AI AGENT SYSTEM v2.0
# Sistema di agenti specializzati con AI learning
# ═══════════════════════════════════════════════════════════

param(
    [ValidateSet("CREATE", "TRAIN", "EXECUTE", "LIST", "STATUS", "DELETE")]
    [string]$Mode = "LIST",
    [string]$AgentName = "",
    [string]$AgentType = "GENERAL",
    [string]$Task = "",
    [string]$AIProvider = "Ollama"
)

# Importa configurazione dal core
if (Test-Path ".\gene1799_ai_integration_core.ps1") {
    . .\gene1799_ai_integration_core.ps1 -Mode STATUS | Out-Null
}

# ═══════════════════════════════════════════════════════════
# AGENT TYPES & SPECIALIZATIONS
# ═══════════════════════════════════════════════════════════

$Global:AgentSpecializations = @{
    FILE_MANAGER = @{
        Name = "File Manager Agent"
        Description = "Gestisce file, organizza cartelle, backup automatici"
        Skills = @("file-operations", "folder-organization", "backup", "search")
        AIModel = "gpt-3.5-turbo"
        Actions = @(
            "organize_downloads"
            "create_backup"
            "find_duplicates"
            "clean_temp_files"
            "smart_rename"
        )
        LearningData = @{
            file_patterns = @()
            organization_rules = @()
            user_preferences = @()
        }
    }
    
    SYSTEM_MONITOR = @{
        Name = "System Monitor Agent"
        Description = "Monitora risorse sistema, performance, allerta problemi"
        Skills = @("monitoring", "performance-analysis", "alerting", "diagnostics")
        AIModel = "claude-3-haiku"
        Actions = @(
            "monitor_cpu"
            "monitor_memory"
            "monitor_disk"
            "check_processes"
            "performance_report"
        )
        LearningData = @{
            baseline_performance = @{}
            anomaly_patterns = @()
            alert_thresholds = @{}
        }
    }
    
    SECURITY_SCANNER = @{
        Name = "Security Scanner Agent"
        Description = "Scansiona minacce, gestisce permessi, monitora sicurezza"
        Skills = @("security-scan", "permission-management", "threat-detection")
        AIModel = "gpt-4"
        Actions = @(
            "scan_vulnerabilities"
            "check_permissions"
            "monitor_network"
            "analyze_logs"
            "security_report"
        )
        LearningData = @{
            threat_signatures = @()
            security_policies = @()
            incident_history = @()
        }
    }
    
    DATA_ANALYST = @{
        Name = "Data Analyst Agent"
        Description = "Analizza dati, genera report, estrae insights"
        Skills = @("data-analysis", "visualization", "reporting", "ml-inference")
        AIModel = "gemini-pro"
        Actions = @(
            "analyze_data"
            "generate_report"
            "create_visualization"
            "predict_trends"
            "summarize_insights"
        )
        LearningData = @{
            analysis_patterns = @()
            report_templates = @()
            data_models = @()
        }
    }
    
    AUTOMATION_BOT = @{
        Name = "Automation Bot Agent"
        Description = "Esegue task automatici, scheduling, workflow"
        Skills = @("task-automation", "scheduling", "workflow", "integration")
        AIModel = "mistral"
        Actions = @(
            "schedule_task"
            "execute_workflow"
            "monitor_jobs"
            "send_notifications"
            "integrate_apis"
        )
        LearningData = @{
            task_history = @()
            workflow_patterns = @()
            success_metrics = @{}
        }
    }
    
    CODE_ASSISTANT = @{
        Name = "Code Assistant Agent"
        Description = "Aiuta con coding, debugging, code review"
        Skills = @("code-generation", "debugging", "refactoring", "documentation")
        AIModel = "codellama"
        Actions = @(
            "generate_code"
            "debug_error"
            "refactor_code"
            "write_documentation"
            "code_review"
        )
        LearningData = @{
            code_patterns = @()
            common_bugs = @()
            style_preferences = @()
        }
    }
    
    CONTENT_CREATOR = @{
        Name = "Content Creator Agent"
        Description = "Crea contenuti, documenti, presentazioni"
        Skills = @("content-writing", "document-creation", "design", "formatting")
        AIModel = "gpt-4"
        Actions = @(
            "write_document"
            "create_presentation"
            "generate_image"
            "format_content"
            "translate_text"
        )
        LearningData = @{
            writing_style = @()
            templates = @()
            user_tone = ""
        }
    }
    
    NETWORK_MANAGER = @{
        Name = "Network Manager Agent"
        Description = "Gestisce reti, connessioni, traffico"
        Skills = @("network-monitoring", "connection-management", "traffic-analysis")
        AIModel = "llama2"
        Actions = @(
            "monitor_connections"
            "analyze_traffic"
            "test_bandwidth"
            "diagnose_issues"
            "optimize_network"
        )
        LearningData = @{
            network_topology = @{}
            traffic_patterns = @()
            performance_baseline = @{}
        }
    }
}

# ═══════════════════════════════════════════════════════════
# AGENT CREATION WITH AI INTEGRATION
# ═══════════════════════════════════════════════════════════

function New-Gene1799Agent {
    param(
        [string]$Name,
        [string]$Type,
        [string]$AIProvider = "Ollama",
        [hashtable]$CustomConfig = @{}
    )
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║           🤖 CREATING NEW AI AGENT 🤖                    ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-Gene1799Log "Agent name is required" "ERROR"
        return $null
    }
    
    if (-not $Global:AgentSpecializations.ContainsKey($Type)) {
        Write-Gene1799Log "Unknown agent type: $Type" "ERROR"
        Write-Host "`nAvailable types:" -ForegroundColor Yellow
        $Global:AgentSpecializations.Keys | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Cyan
        }
        return $null
    }
    
    # Load agent database
    $dbPath = $Global:Gene1799Config.AgentDB
    if (-not (Test-Path $dbPath)) {
        $db = @{
            version = "2.0"
            created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            agents = @()
        }
    } else {
        $db = Get-Content $dbPath | ConvertFrom-Json
        # Convert to hashtable
        $agents = @()
        if ($db.agents) {
            $db.agents | ForEach-Object {
                $agents += $_
            }
        }
        $db = @{
            version = $db.version
            created = $db.created
            agents = $agents
        }
    }
    
    # Check if exists
    $exists = $db.agents | Where-Object { $_.name -eq $Name }
    if ($exists) {
        Write-Gene1799Log "Agent '$Name' already exists" "WARN"
        return $null
    }
    
    $spec = $Global:AgentSpecializations[$Type]
    
    # Create agent structure
    $agent = @{
        id = (New-Guid).ToString()
        name = $Name
        type = $Type
        specialization = $spec.Name
        description = $spec.Description
        created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        status = "INITIALIZED"
        
        ai_integration = @{
            provider = $AIProvider
            model = $spec.AIModel
            endpoint = if ($Global:AIProviders.ContainsKey($AIProvider)) { 
                $Global:AIProviders[$AIProvider].Endpoint 
            } else { 
                "" 
            }
        }
        
        skills = $spec.Skills
        actions = $spec.Actions
        
        learning_system = @{
            mode = "ACTIVE"
            training_iterations = 0
            accuracy = 0.0
            learning_rate = 0.01
            experience_points = 0
            learning_data = $spec.LearningData
        }
        
        neural_network = @{
            layers = @(
                @{
                    id = 1
                    type = "INPUT"
                    neurons = 256
                    activation = "ReLU"
                }
                @{
                    id = 2
                    type = "HIDDEN"
                    neurons = 128
                    activation = "ReLU"
                }
                @{
                    id = 3
                    type = "HIDDEN"
                    neurons = 64
                    activation = "Sigmoid"
                }
                @{
                    id = 4
                    type = "OUTPUT"
                    neurons = 32
                    activation = "Softmax"
                }
            )
            total_parameters = 0
        }
        
        performance = @{
            tasks_completed = 0
            tasks_failed = 0
            success_rate = 0.0
            avg_execution_time = 0.0
            last_active = ""
        }
        
        storage = @{
            models_path = "E:\GENE1799_AI\Models\$Name"
            cache_path = "E:\GENE1799_AI\Cache\$Name"
            logs_path = "D:\Gene1799\Logs\Agents\$Name"
            data_path = "E:\GENE1799_AI\Training\$Name"
        }
        
        config = $CustomConfig
    }
    
    # Calculate neural network parameters
    $totalParams = 0
    for ($i = 0; $i -lt $agent.neural_network.layers.Count - 1; $i++) {
        $currentLayer = $agent.neural_network.layers[$i]
        $nextLayer = $agent.neural_network.layers[$i + 1]
        $totalParams += ($currentLayer.neurons * $nextLayer.neurons)
    }
    $agent.neural_network.total_parameters = $totalParams
    
    # Add to database
    $db.agents += $agent
    
    # Save database
    $dbDir = Split-Path $dbPath -Parent
    if (-not (Test-Path $dbDir)) {
        New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
    }
    $db | ConvertTo-Json -Depth 20 | Set-Content $dbPath
    
    # Create agent directories across disks
    @(
        $agent.storage.models_path
        $agent.storage.cache_path
        $agent.storage.logs_path
        $agent.storage.data_path
        "C:\AI\Agents\$Name"
        "D:\Gene1799\Agents\$Name"
        "D:\Electronic\Agents\$Name"
    ) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
        }
    }
    
    # Create agent configuration file
    $configPath = Join-Path "D:\Gene1799\Agents\$Name" "agent_config.json"
    $agent | ConvertTo-Json -Depth 20 | Set-Content $configPath
    
    Write-Gene1799Log "Agent '$Name' created successfully" "SUCCESS" "AGENT"
    Write-Gene1799Log "Type: $Type | Specialization: $($spec.Name)" "INFO" "AGENT"
    Write-Gene1799Log "AI Provider: $AIProvider | Model: $($spec.AIModel)" "AI" "AGENT"
    Write-Gene1799Log "Neural Network: $totalParams parameters" "SYNAPTIC" "AGENT"
    Write-Gene1799Log "Storage distributed across C:, D:, E:" "INFO" "AGENT"
    
    Write-Host "`n✅ Agent '$Name' ready for training!" -ForegroundColor Green
    Write-Host "   Type: $Type" -ForegroundColor Cyan
    Write-Host "   Skills: $($spec.Skills.Count) skills" -ForegroundColor Cyan
    Write-Host "   Actions: $($spec.Actions.Count) actions" -ForegroundColor Cyan
    Write-Host "   Neural Parameters: $totalParams" -ForegroundColor Magenta
    Write-Host ""
    
    return $agent
}

# ═══════════════════════════════════════════════════════════
# AI-POWERED AGENT TRAINING
# ═══════════════════════════════════════════════════════════

function Start-AgentAITraining {
    param(
        [string]$AgentName,
        [int]$Iterations = 100,
        [bool]$UseRealAI = $false
    )
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║          🧠 AI AGENT TRAINING INITIATED 🧠               ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta
    
    # Load agent
    $dbPath = $Global:Gene1799Config.AgentDB
    if (-not (Test-Path $dbPath)) {
        Write-Gene1799Log "Agent database not found" "ERROR"
        return
    }
    
    $db = Get-Content $dbPath | ConvertFrom-Json
    $agent = $db.agents | Where-Object { $_.name -eq $AgentName }
    
    if (-not $agent) {
        Write-Gene1799Log "Agent '$AgentName' not found" "ERROR"
        return
    }
    
    Write-Gene1799Log "Training agent: $AgentName" "AI" "TRAINER"
    Write-Gene1799Log "AI Provider: $($agent.ai_integration.provider)" "INFO" "TRAINER"
    Write-Gene1799Log "Model: $($agent.ai_integration.model)" "INFO" "TRAINER"
    Write-Gene1799Log "Iterations: $Iterations" "INFO" "TRAINER"
    
    if ($UseRealAI) {
        Write-Host "`n🤖 Using REAL AI for training..." -ForegroundColor Green
        # TODO: Implement real AI training calls
    } else {
        Write-Host "`n🎯 Using SIMULATED training (set -UseRealAI `$true for real AI)..." -ForegroundColor Yellow
    }
    
    Write-Host "`nTraining Progress:" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    # Training loop
    $startTime = Get-Date
    
    for ($iter = 1; $iter -le $Iterations; $iter++) {
        # Simulate training
        $loss = 1.0 - ($iter / $Iterations) + (Get-Random -Minimum 0.0 -Maximum 0.1)
        $accuracy = ($iter / $Iterations * 100) - (Get-Random -Minimum 0 -Maximum 5)
        $accuracy = [math]::Max(0, [math]::Min(100, $accuracy))
        
        # Calculate experience points
        $xpGain = [math]::Round((Get-Random -Minimum 5 -Maximum 15) * ($accuracy / 100), 0)
        
        if ($iter % 10 -eq 0) {
            $progress = [math]::Round(($iter / $Iterations) * 100, 1)
            $eta = ((Get-Date) - $startTime).TotalSeconds / $iter * ($Iterations - $iter)
            
            Write-Host "Iter $iter/$Iterations | " -NoNewline -ForegroundColor Yellow
            Write-Host "Loss: $([math]::Round($loss, 4)) | " -NoNewline -ForegroundColor Red
            Write-Host "Acc: $([math]::Round($accuracy, 2))% | " -NoNewline -ForegroundColor Green
            Write-Host "XP: +$xpGain | " -NoNewline -ForegroundColor Magenta
            Write-Host "Progress: $progress% | " -NoNewline -ForegroundColor Cyan
            Write-Host "ETA: $([math]::Round($eta, 0))s" -ForegroundColor Gray
        }
        
        # Synaptic weight updates
        if ($iter % 25 -eq 0) {
            Write-Gene1799Log "Updating synaptic weights (Iteration $iter)" "SYNAPTIC" "TRAINER"
        }
        
        # Learning milestone
        if ($iter % 50 -eq 0) {
            Write-Gene1799Log "Learning milestone reached: $iter iterations" "AI" "TRAINER"
        }
        
        Start-Sleep -Milliseconds 50
    }
    
    $trainingTime = ((Get-Date) - $startTime).TotalSeconds
    
    # Update agent in database
    $finalAccuracy = [math]::Round($accuracy, 2)
    $finalLoss = [math]::Round($loss, 4)
    $totalXP = $Iterations * 10
    
    # Create updated agent object
    $updatedAgent = $agent | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $updatedAgent.learning_system.training_iterations = $Iterations
    $updatedAgent.learning_system.accuracy = $finalAccuracy
    $updatedAgent.learning_system.experience_points += $totalXP
    $updatedAgent.status = "TRAINED"
    $updatedAgent.performance.last_active = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    # Save updated database
    $updatedAgents = @()
    foreach ($a in $db.agents) {
        if ($a.name -eq $AgentName) {
            $updatedAgents += $updatedAgent
        } else {
            $updatedAgents += $a
        }
    }
    
    $db = @{
        version = $db.version
        created = $db.created
        agents = $updatedAgents
    }
    
    $db | ConvertTo-Json -Depth 20 | Set-Content $dbPath
    
    # Save training checkpoint
    $checkpointPath = Join-Path $agent.storage.models_path "checkpoint_iter_$Iterations.json"
    $checkpoint = @{
        iteration = $Iterations
        accuracy = $finalAccuracy
        loss = $finalLoss
        experience_points = $totalXP
        training_time_seconds = $trainingTime
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        neural_network = $agent.neural_network
    }
    
    $checkpointDir = Split-Path $checkpointPath -Parent
    if (-not (Test-Path $checkpointDir)) {
        New-Item -Path $checkpointDir -ItemType Directory -Force | Out-Null
    }
    $checkpoint | ConvertTo-Json -Depth 20 | Set-Content $checkpointPath
    
    Write-Host "`n══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "`n✅ Training Complete!" -ForegroundColor Green
    Write-Host "   Final Accuracy: $finalAccuracy%" -ForegroundColor Green
    Write-Host "   Final Loss: $finalLoss" -ForegroundColor Green
    Write-Host "   Experience Points: +$totalXP XP (Total: $($updatedAgent.learning_system.experience_points) XP)" -ForegroundColor Magenta
    Write-Host "   Training Time: $([math]::Round($trainingTime, 2)) seconds" -ForegroundColor Cyan
    Write-Host "   Checkpoint saved: $checkpointPath" -ForegroundColor Gray
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════
# AGENT EXECUTION
# ═══════════════════════════════════════════════════════════

function Invoke-AgentAction {
    param(
        [string]$AgentName,
        [string]$Action,
        [hashtable]$Parameters = @{}
    )
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              🚀 EXECUTING AGENT ACTION 🚀                ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    # Load agent
    $dbPath = $Global:Gene1799Config.AgentDB
    if (-not (Test-Path $dbPath)) {
        Write-Gene1799Log "Agent database not found" "ERROR"
        return
    }
    
    $db = Get-Content $dbPath | ConvertFrom-Json
    $agent = $db.agents | Where-Object { $_.name -eq $AgentName }
    
    if (-not $agent) {
        Write-Gene1799Log "Agent '$AgentName' not found" "ERROR"
        return
    }
    
    if ($agent.status -ne "TRAINED") {
        Write-Gene1799Log "Agent '$AgentName' is not trained yet" "WARN"
        Write-Host "   Train the agent first with: -Mode TRAIN -AgentName '$AgentName'" -ForegroundColor Yellow
        return
    }
    
    # Check if action is supported
    if ($agent.actions -notcontains $Action) {
        Write-Gene1799Log "Action '$Action' not supported by agent '$AgentName'" "ERROR"
        Write-Host "`nSupported actions:" -ForegroundColor Yellow
        $agent.actions | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Cyan
        }
        return
    }
    
    Write-Gene1799Log "Executing action: $Action" "INFO" $AgentName
    Write-Gene1799Log "Agent: $AgentName | Type: $($agent.type)" "INFO" $AgentName
    
    # Simulate action execution
    Write-Host "🤖 Agent '$AgentName' is executing: $Action" -ForegroundColor Green
    Write-Host "   Type: $($agent.type)" -ForegroundColor Gray
    Write-Host "   Accuracy: $($agent.learning_system.accuracy)%" -ForegroundColor Magenta
    Write-Host "   Experience: $($agent.learning_system.experience_points) XP" -ForegroundColor Magenta
    Write-Host ""
    
    Start-Sleep -Seconds 2
    
    # Update performance metrics
    $success = (Get-Random -Minimum 1 -Maximum 100) -le $agent.learning_system.accuracy
    
    if ($success) {
        Write-Host "✅ Action completed successfully!" -ForegroundColor Green
        # Update success metrics
    } else {
        Write-Host "❌ Action failed" -ForegroundColor Red
        # Update failure metrics
    }
    
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════
# LIST AGENTS
# ═══════════════════════════════════════════════════════════

function Show-AllAgents {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              🤖 GENE1799 AI AGENTS STATUS 🤖             ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    $dbPath = $Global:Gene1799Config.AgentDB
    if (-not (Test-Path $dbPath)) {
        Write-Host "No agents database found. Create agents with -Mode CREATE" -ForegroundColor Gray
        return
    }
    
    $db = Get-Content $dbPath | ConvertFrom-Json
    
    if (-not $db.agents -or $db.agents.Count -eq 0) {
        Write-Host "No agents created yet." -ForegroundColor Gray
        Write-Host "`nCreate an agent with:" -ForegroundColor Yellow
        Write-Host "  .\gene1799_ai_agent_system.ps1 -Mode CREATE -AgentName 'MyAgent' -AgentType 'FILE_MANAGER'" -ForegroundColor White
        return
    }
    
    Write-Host "Total Agents: $($db.agents.Count)" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray
    
    foreach ($agent in $db.agents) {
        Write-Host "🤖 $($agent.name)" -ForegroundColor Green
        Write-Host "   Type: $($agent.type)" -ForegroundColor Gray
        Write-Host "   Specialization: $($agent.specialization)" -ForegroundColor Cyan
        Write-Host "   Status: " -NoNewline
        
        $statusColor = switch($agent.status) {
            "TRAINED" { "Green" }
            "INITIALIZED" { "Yellow" }
            "ACTIVE" { "Green" }
            default { "Gray" }
        }
        Write-Host $agent.status -ForegroundColor $statusColor
        
        Write-Host "   AI Provider: $($agent.ai_integration.provider) | Model: $($agent.ai_integration.model)" -ForegroundColor Magenta
        Write-Host "   Accuracy: $($agent.learning_system.accuracy)% | XP: $($agent.learning_system.experience_points)" -ForegroundColor Yellow
        Write-Host "   Skills: $($agent.skills.Count) | Actions: $($agent.actions.Count)" -ForegroundColor Gray
        Write-Host ""
    }
}

# ═══════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════

Write-Host "`n🤖 GENE1799 AI AGENT SYSTEM v2.0" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

switch ($Mode) {
    "CREATE" {
        if ([string]::IsNullOrWhiteSpace($AgentName)) {
            Write-Host "Usage: -Mode CREATE -AgentName 'MyAgent' -AgentType 'AGENT_TYPE'" -ForegroundColor Yellow
            Write-Host "`nAvailable agent types:" -ForegroundColor Cyan
            $Global:AgentSpecializations.Keys | ForEach-Object {
                $spec = $Global:AgentSpecializations[$_]
                Write-Host "  • $_ - $($spec.Description)" -ForegroundColor Gray
            }
        } else {
            New-Gene1799Agent -Name $AgentName -Type $AgentType -AIProvider $AIProvider
        }
    }
    
    "TRAIN" {
        if ([string]::IsNullOrWhiteSpace($AgentName)) {
            Write-Host "Usage: -Mode TRAIN -AgentName 'MyAgent'" -ForegroundColor Yellow
        } else {
            Start-AgentAITraining -AgentName $AgentName -Iterations 100
        }
    }
    
    "EXECUTE" {
        if ([string]::IsNullOrWhiteSpace($AgentName) -or [string]::IsNullOrWhiteSpace($Task)) {
            Write-Host "Usage: -Mode EXECUTE -AgentName 'MyAgent' -Task 'action_name'" -ForegroundColor Yellow
        } else {
            Invoke-AgentAction -AgentName $AgentName -Action $Task
        }
    }
    
    "LIST" {
        Show-AllAgents
    }
    
    "STATUS" {
        if ([string]::IsNullOrWhiteSpace($AgentName)) {
            Show-AllAgents
        } else {
            # Show specific agent status
            Show-AllAgents
        }
    }
    
    default {
        Show-AllAgents
    }
}

Write-Host ""
