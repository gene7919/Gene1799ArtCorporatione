# ═══════════════════════════════════════════════════════════
# 🎨 GENE1799 NEURAL HUB - Interactive GUI
# ═══════════════════════════════════════════════════════════

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "🧠 GENE1799 Neural Hub Control Center"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = [System.Drawing.Color]::White

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(860, 40)
$titleLabel.Text = "🧠 GENE1799 NEURAL HUB - Synaptic Agent Management System"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::Cyan
$form.Controls.Add($titleLabel)

# Status Panel
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(20, 70)
$statusPanel.Size = New-Object System.Drawing.Size(860, 120)
$statusPanel.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$statusPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($statusPanel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 10)
$statusLabel.Size = New-Object System.Drawing.Size(840, 100)
$statusLabel.Font = New-Object System.Drawing.Font("Consolas", 9)
$statusLabel.ForeColor = [System.Drawing.Color]::LightGreen
$statusLabel.Text = "System Status: Initializing..."
$statusPanel.Controls.Add($statusLabel)

# Initialize System Button
$btnInit = New-Object System.Windows.Forms.Button
$btnInit.Location = New-Object System.Drawing.Point(20, 210)
$btnInit.Size = New-Object System.Drawing.Size(200, 50)
$btnInit.Text = "🚀 Initialize System"
$btnInit.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnInit.ForeColor = [System.Drawing.Color]::White
$btnInit.FlatStyle = "Flat"
$btnInit.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnInit)

# Agent Name Input
$labelAgentName = New-Object System.Windows.Forms.Label
$labelAgentName.Location = New-Object System.Drawing.Point(240, 210)
$labelAgentName.Size = New-Object System.Drawing.Size(100, 20)
$labelAgentName.Text = "Agent Name:"
$labelAgentName.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($labelAgentName)

$txtAgentName = New-Object System.Windows.Forms.TextBox
$txtAgentName.Location = New-Object System.Drawing.Point(240, 235)
$txtAgentName.Size = New-Object System.Drawing.Size(200, 25)
$txtAgentName.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$txtAgentName.ForeColor = [System.Drawing.Color]::White
$txtAgentName.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($txtAgentName)

# Agent Type Dropdown
$labelAgentType = New-Object System.Windows.Forms.Label
$labelAgentType.Location = New-Object System.Drawing.Point(460, 210)
$labelAgentType.Size = New-Object System.Drawing.Size(100, 20)
$labelAgentType.Text = "Agent Type:"
$labelAgentType.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($labelAgentType)

$comboAgentType = New-Object System.Windows.Forms.ComboBox
$comboAgentType.Location = New-Object System.Drawing.Point(460, 235)
$comboAgentType.Size = New-Object System.Drawing.Size(200, 25)
$comboAgentType.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$comboAgentType.ForeColor = [System.Drawing.Color]::White
$comboAgentType.Font = New-Object System.Drawing.Font("Consolas", 10)
$comboAgentType.DropDownStyle = "DropDownList"
$comboAgentType.Items.AddRange(@("CLASSIFIER", "PREDICTOR", "GENERATOR", "ANALYZER", "OPTIMIZER", "GENERAL"))
$comboAgentType.SelectedIndex = 0
$form.Controls.Add($comboAgentType)

# Add Agent Button
$btnAddAgent = New-Object System.Windows.Forms.Button
$btnAddAgent.Location = New-Object System.Drawing.Point(680, 210)
$btnAddAgent.Size = New-Object System.Drawing.Size(200, 50)
$btnAddAgent.Text = "➕ Add Agent"
$btnAddAgent.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
$btnAddAgent.ForeColor = [System.Drawing.Color]::White
$btnAddAgent.FlatStyle = "Flat"
$btnAddAgent.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnAddAgent)

# Agent List
$labelAgentList = New-Object System.Windows.Forms.Label
$labelAgentList.Location = New-Object System.Drawing.Point(20, 280)
$labelAgentList.Size = New-Object System.Drawing.Size(200, 20)
$labelAgentList.Text = "🤖 Registered Agents:"
$labelAgentList.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($labelAgentList)

$listAgents = New-Object System.Windows.Forms.ListBox
$listAgents.Location = New-Object System.Drawing.Point(20, 310)
$listAgents.Size = New-Object System.Drawing.Size(420, 200)
$listAgents.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$listAgents.ForeColor = [System.Drawing.Color]::Cyan
$listAgents.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($listAgents)

# Train Agent Button
$btnTrain = New-Object System.Windows.Forms.Button
$btnTrain.Location = New-Object System.Drawing.Point(460, 310)
$btnTrain.Size = New-Object System.Drawing.Size(200, 50)
$btnTrain.Text = "🧠 Train Agent"
$btnTrain.BackColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
$btnTrain.ForeColor = [System.Drawing.Color]::White
$btnTrain.FlatStyle = "Flat"
$btnTrain.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnTrain)

# Refresh Status Button
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Location = New-Object System.Drawing.Point(680, 310)
$btnRefresh.Size = New-Object System.Drawing.Size(200, 50)
$btnRefresh.Text = "🔄 Refresh Status"
$btnRefresh.BackColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
$btnRefresh.ForeColor = [System.Drawing.Color]::White
$btnRefresh.FlatStyle = "Flat"
$btnRefresh.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnRefresh)

# Activity Log
$labelLog = New-Object System.Windows.Forms.Label
$labelLog.Location = New-Object System.Drawing.Point(20, 530)
$labelLog.Size = New-Object System.Drawing.Size(200, 20)
$labelLog.Text = "📋 Activity Log:"
$labelLog.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($labelLog)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 560)
$txtLog.Size = New-Object System.Drawing.Size(860, 80)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.BackColor = [System.Drawing.Color]::Black
$txtLog.ForeColor = [System.Drawing.Color]::LightGreen
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.ReadOnly = $true
$form.Controls.Add($txtLog)

# Functions
function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$timestamp] $message`r`n")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
}

function Update-Status {
    $status = "🔗 CONNECTIONS:`r`n"
    $status += "  C:\AI: " + $(if (Test-Path "C:\AI") { "✓ ONLINE" } else { "✗ OFFLINE" }) + "`r`n"
    $status += "  D:\Gene1799: " + $(if (Test-Path "D:\Gene1799") { "✓ ONLINE" } else { "✗ OFFLINE" }) + "`r`n"
    $status += "  D:\Electronic: " + $(if (Test-Path "D:\Electronic") { "✓ ONLINE" } else { "✗ OFFLINE" }) + "`r`n"
    
    $dbPath = "D:\Gene1799\Database\agents.json"
    if (Test-Path $dbPath) {
        $db = Get-Content $dbPath | ConvertFrom-Json
        $status += "`r`n🤖 AGENTS: " + $db.agents.Count + " registered"
    }
    
    $statusLabel.Text = $status
}

function Refresh-AgentList {
    $listAgents.Items.Clear()
    $dbPath = "D:\Gene1799\Database\agents.json"
    if (Test-Path $dbPath) {
        $db = Get-Content $dbPath | ConvertFrom-Json
        foreach ($agent in $db.agents) {
            $listAgents.Items.Add("$($agent.name) [$($agent.type)] - $($agent.status)")
        }
    }
}

# Button Click Events
$btnInit.Add_Click({
    Log-Message "Initializing Neural Hub..."
    & "D:\Gene1799\Explorer\gene1799_neural_hub.ps1" -Mode INIT
    Log-Message "Neural Hub initialized successfully!"
    Update-Status
})

$btnAddAgent.Add_Click({
    $name = $txtAgentName.Text
    $type = $comboAgentType.SelectedItem
    
    if ([string]::IsNullOrWhiteSpace($name)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter an agent name", "Error", "OK", "Error")
        return
    }
    
    Log-Message "Adding agent: $name ($type)..."
    & "D:\Gene1799\Explorer\gene1799_neural_hub.ps1" -Mode ADD_AGENT -AgentName $name -AgentType $type
    Log-Message "Agent '$name' added successfully!"
    
    $txtAgentName.Clear()
    Refresh-AgentList
    Update-Status
})

$btnTrain.Add_Click({
    if ($listAgents.SelectedItem -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Please select an agent to train", "Error", "OK", "Error")
        return
    }
    
    $selectedText = $listAgents.SelectedItem.ToString()
    $agentName = $selectedText.Split('[')[0].Trim()
    
    Log-Message "Training agent: $agentName (this may take a moment)..."
    & "D:\Gene1799\Explorer\gene1799_neural_hub.ps1" -Mode TRAIN -AgentName $agentName
    Log-Message "Training completed for '$agentName'!"
    
    Refresh-AgentList
    Update-Status
})

$btnRefresh.Add_Click({
    Log-Message "Refreshing system status..."
    Update-Status
    Refresh-AgentList
    Log-Message "Status refreshed!"
})

# Initial Load
Update-Status
Refresh-AgentList
Log-Message "GENE1799 Neural Hub GUI loaded successfully!"

# Show Form
[void]$form.ShowDialog()
