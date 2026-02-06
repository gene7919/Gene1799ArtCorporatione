#Requires -Version 7.0
<#
.SYNOPSIS
    GENE1799 Desktop Monitor GUI - Interfaccia Grafica Sistema
.DESCRIPTION
    Monitor in tempo reale per visualizzare e controllare tutti gli agenti AI,
    statistiche, performance e operazioni in corso
.AUTHOR
    Gene1799 Art Corporation
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Importa il Core
. "D:\Gene1799\Explorer\gene1799_ai_integration_core.ps1" -Mode START

# ═══════════════════════════════════════════════════════════════════
#  XAML GUI DEFINITION
# ═══════════════════════════════════════════════════════════════════

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="GENE1799 AI Control Center" 
    Height="800" 
    Width="1400"
    WindowStartupLocation="CenterScreen"
    Background="#1E1E1E"
    ResizeMode="CanResize">
    
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#007ACC"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        
        <Style TargetType="ListBox">
            <Setter Property="Background" Value="#252526"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
        </Style>
        
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#252526"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="Padding" Value="5"/>
        </Style>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="200"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#007ACC" Padding="15">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0">
                    <TextBlock Text="GENE1799 AI CONTROL CENTER" FontSize="24" FontWeight="Bold"/>
                    <TextBlock Name="StatusText" Text="Sistema Attivo • 0 Agenti Operativi" FontSize="12" Opacity="0.8"/>
                </StackPanel>
                
                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <Button Name="BtnRefresh" Content="🔄 Aggiorna" Width="120"/>
                    <Button Name="BtnSettings" Content="⚙️ Settings" Width="120"/>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- Main Content -->
        <Grid Grid.Row="1" Margin="10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="350"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <!-- Left Panel - Agents List -->
            <Border Grid.Column="0" Background="#252526" BorderBrush="#3F3F46" BorderThickness="1" Margin="0,0,5,0">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <TextBlock Grid.Row="0" Text="🤖 AGENTI ATTIVI" FontSize="16" FontWeight="Bold" Margin="10" Foreground="#007ACC"/>
                    
                    <ListBox Grid.Row="1" Name="AgentsList" Margin="10" SelectionMode="Single">
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <Border BorderBrush="#3F3F46" BorderThickness="0,0,0,1" Padding="5" Margin="0,5">
                                    <StackPanel>
                                        <TextBlock Text="{Binding Name}" FontWeight="Bold" FontSize="14"/>
                                        <TextBlock Text="{Binding Type}" Foreground="#808080" FontSize="10"/>
                                        <StackPanel Orientation="Horizontal" Margin="0,5,0,0">
                                            <TextBlock Text="{Binding Status}" Foreground="#4EC9B0" Margin="0,0,10,0"/>
                                            <TextBlock Text="{Binding PerformanceText}" Foreground="#DCDCAA"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Border>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>
                    
                    <StackPanel Grid.Row="2" Margin="10">
                        <Button Name="BtnCreateAgent" Content="➕ Crea Nuovo Agente" Height="35"/>
                        <Button Name="BtnTrainAgent" Content="🎓 Avvia Training" Height="35"/>
                        <Button Name="BtnDeployAgent" Content="🚀 Deploy Agente" Height="35"/>
                    </StackPanel>
                </Grid>
            </Border>
            
            <!-- Right Panel - Details and Actions -->
            <Border Grid.Column="1" Background="#252526" BorderBrush="#3F3F46" BorderThickness="1" Margin="5,0,0,0">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <!-- Tabs -->
                    <TabControl Grid.Row="1" Name="MainTabs" Background="#252526" BorderThickness="0">
                        <TabItem Header="📊 Dashboard">
                            <ScrollViewer>
                                <StackPanel Margin="20">
                                    <TextBlock Text="STATISTICHE SISTEMA" FontSize="18" FontWeight="Bold" Foreground="#007ACC" Margin="0,0,0,15"/>
                                    
                                    <!-- Stats Grid -->
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>
                                        
                                        <Border Grid.Column="0" Background="#1E1E1E" Padding="15" Margin="5">
                                            <StackPanel>
                                                <TextBlock Text="Agenti Totali" FontSize="12" Opacity="0.7"/>
                                                <TextBlock Name="StatTotalAgents" Text="0" FontSize="32" FontWeight="Bold" Foreground="#4EC9B0"/>
                                            </StackPanel>
                                        </Border>
                                        
                                        <Border Grid.Column="1" Background="#1E1E1E" Padding="15" Margin="5">
                                            <StackPanel>
                                                <TextBlock Text="Azioni Oggi" FontSize="12" Opacity="0.7"/>
                                                <TextBlock Name="StatActionsToday" Text="0" FontSize="32" FontWeight="Bold" Foreground="#DCDCAA"/>
                                            </StackPanel>
                                        </Border>
                                        
                                        <Border Grid.Column="2" Background="#1E1E1E" Padding="15" Margin="5">
                                            <StackPanel>
                                                <TextBlock Text="Success Rate" FontSize="12" Opacity="0.7"/>
                                                <TextBlock Name="StatSuccessRate" Text="0%" FontSize="32" FontWeight="Bold" Foreground="#569CD6"/>
                                            </StackPanel>
                                        </Border>
                                    </Grid>
                                    
                                    <Separator Margin="0,20" Background="#3F3F46"/>
                                    
                                    <TextBlock Text="KNOWLEDGE BASE" FontSize="18" FontWeight="Bold" Foreground="#007ACC" Margin="0,0,0,15"/>
                                    
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>
                                        
                                        <Border Grid.Column="0" Background="#1E1E1E" Padding="15" Margin="5">
                                            <StackPanel>
                                                <TextBlock Text="📚 Esperienze" FontSize="14" Margin="0,0,0,10"/>
                                                <TextBlock Name="StatExperiences" Text="0" FontSize="24" Foreground="#CE9178"/>
                                            </StackPanel>
                                        </Border>
                                        
                                        <Border Grid.Column="1" Background="#1E1E1E" Padding="15" Margin="5">
                                            <StackPanel>
                                                <TextBlock Text="✨ Pattern Scoperti" FontSize="14" Margin="0,0,0,10"/>
                                                <TextBlock Name="StatPatterns" Text="0" FontSize="24" Foreground="#C586C0"/>
                                            </StackPanel>
                                        </Border>
                                    </Grid>
                                    
                                    <Separator Margin="0,20" Background="#3F3F46"/>
                                    
                                    <TextBlock Text="OPERAZIONI VELOCI" FontSize="18" FontWeight="Bold" Foreground="#007ACC" Margin="0,0,0,15"/>
                                    
                                    <WrapPanel>
                                        <Button Name="BtnQuickOrganize" Content="🗂️ Organizza Downloads" Width="180" Height="40" Margin="5"/>
                                        <Button Name="BtnQuickCleanup" Content="🧹 Pulizia Sistema" Width="180" Height="40" Margin="5"/>
                                        <Button Name="BtnQuickBackup" Content="💾 Backup Rapido" Width="180" Height="40" Margin="5"/>
                                        <Button Name="BtnQuickAnalyze" Content="📊 Analizza Dati" Width="180" Height="40" Margin="5"/>
                                        <Button Name="BtnEvolution" Content="🧬 Evoluzione Agenti" Width="180" Height="40" Margin="5"/>
                                    </WrapPanel>
                                </StackPanel>
                            </ScrollViewer>
                        </TabItem>
                        
                        <TabItem Header="👤 Dettagli Agente">
                            <ScrollViewer>
                                <StackPanel Name="AgentDetailsPanel" Margin="20">
                                    <TextBlock Text="Seleziona un agente dalla lista per vedere i dettagli" 
                                              FontSize="14" 
                                              Foreground="#808080" 
                                              HorizontalAlignment="Center" 
                                              VerticalAlignment="Center"
                                              Margin="0,50,0,0"/>
                                </StackPanel>
                            </ScrollViewer>
                        </TabItem>
                        
                        <TabItem Header="📈 Performance">
                            <ScrollViewer>
                                <StackPanel Margin="20">
                                    <TextBlock Text="ANALISI PERFORMANCE" FontSize="18" FontWeight="Bold" Foreground="#007ACC" Margin="0,0,0,15"/>
                                    <ListBox Name="PerformanceList" Height="500" Background="#1E1E1E">
                                        <ListBox.ItemTemplate>
                                            <DataTemplate>
                                                <Border BorderBrush="#3F3F46" BorderThickness="0,0,0,1" Padding="10" Margin="5">
                                                    <Grid>
                                                        <Grid.ColumnDefinitions>
                                                            <ColumnDefinition Width="*"/>
                                                            <ColumnDefinition Width="Auto"/>
                                                        </Grid.ColumnDefinitions>
                                                        <StackPanel Grid.Column="0">
                                                            <TextBlock Text="{Binding Action}" FontWeight="Bold"/>
                                                            <TextBlock Text="{Binding Agent}" Foreground="#808080" FontSize="10"/>
                                                        </StackPanel>
                                                        <StackPanel Grid.Column="1" Orientation="Horizontal">
                                                            <TextBlock Text="{Binding SuccessRate}" Foreground="#4EC9B0" Margin="0,0,10,0"/>
                                                            <TextBlock Text="{Binding Count}" Foreground="#808080"/>
                                                        </StackPanel>
                                                    </Grid>
                                                </Border>
                                            </DataTemplate>
                                        </ListBox.ItemTemplate>
                                    </ListBox>
                                </StackPanel>
                            </ScrollViewer>
                        </TabItem>
                        
                        <TabItem Header="📝 Log Sistema">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                
                                <TextBox Name="LogTextBox" 
                                        Grid.Row="0"
                                        IsReadOnly="True" 
                                        TextWrapping="Wrap" 
                                        VerticalScrollBarVisibility="Auto"
                                        FontFamily="Consolas"
                                        FontSize="11"
                                        Margin="10"/>
                                
                                <Button Name="BtnClearLog" Grid.Row="1" Content="🗑️ Pulisci Log" Width="120" HorizontalAlignment="Right" Margin="10"/>
                            </Grid>
                        </TabItem>
                    </TabControl>
                </Grid>
            </Border>
        </Grid>
        
        <!-- Bottom Status Bar -->
        <Border Grid.Row="2" Background="#007ACC" Padding="10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <TextBox Name="CommandInput" 
                        Grid.Column="0" 
                        Margin="0,0,10,0"
                        Background="#252526"
                        Foreground="#FFFFFF"
                        BorderBrush="#3F3F46"
                        Height="30"
                        VerticalContentAlignment="Center"
                        Text="Inserisci comando..."/>
                
                <Button Name="BtnExecute" Grid.Column="1" Content="▶️ Esegui" Width="100" Height="30"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# ═══════════════════════════════════════════════════════════════════
#  GUI FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

function Update-AgentsList {
    param($ListBox)
    
    $agents = Get-AllAgentsForGUI
    $ListBox.Items.Clear()
    
    foreach ($agent in $agents) {
        $item = [PSCustomObject]@{
            Name = $agent.Name
            Type = $agent.Type
            Status = $agent.Status
            Performance = $agent.Performance
            PerformanceText = "Perf: $($agent.Performance.ToString('P0'))"
        }
        $ListBox.Items.Add($item)
    }
}

function Get-AllAgentsForGUI {
    $agents = @()
    
    foreach ($type in @('SOCIAL_MEDIA', 'FILE_MANAGER', 'DATA_ANALYST', 'CONTENT_CREATOR')) {
        $typePath = Join-Path $Global:Gene1799Config.AgentsPath $type
        
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

function Update-Statistics {
    param($Window)
    
    $agents = Get-AllAgentsForGUI
    
    # Statistiche base
    $Window.FindName("StatTotalAgents").Text = $agents.Count
    
    # Azioni oggi
    $actionsToday = ($agents | Measure-Object -Property ActionsCount -Sum).Sum
    $Window.FindName("StatActionsToday").Text = $actionsToday
    
    # Success Rate medio
    if ($agents.Count -gt 0) {
        $avgPerformance = ($agents | Measure-Object -Property Performance -Average).Average
        $Window.FindName("StatSuccessRate").Text = $avgPerformance.ToString('P0')
    }
    
    # Knowledge Base
    $kbFile = Join-Path $Global:Gene1799Config.KnowledgePath "knowledge_base.json"
    if (Test-Path $kbFile) {
        try {
            $kb = Get-Content $kbFile -Raw | ConvertFrom-Json
            $Window.FindName("StatExperiences").Text = $kb.Experiences.Count
            $Window.FindName("StatPatterns").Text = $kb.Patterns.Count
        }
        catch {}
    }
}

function Update-PerformanceList {
    param($Window)
    
    $perfList = $Window.FindName("PerformanceList")
    $perfList.Items.Clear()
    
    $kbFile = Join-Path $Global:Gene1799Config.KnowledgePath "knowledge_base.json"
    if (Test-Path $kbFile) {
        try {
            $kb = Get-Content $kbFile -Raw | ConvertFrom-Json
            
            foreach ($key in $kb.SuccessRates.PSObject.Properties.Name) {
                $rate = $kb.SuccessRates.$key
                
                $parts = $key -split '-'
                $agentName = $parts[0]
                $action = $parts[1..($parts.Length-1)] -join '-'
                
                $item = [PSCustomObject]@{
                    Agent = $agentName
                    Action = $action
                    SuccessRate = $rate.Rate.ToString('P0')
                    Count = "$($rate.Success)/$($rate.Total)"
                }
                
                $perfList.Items.Add($item)
            }
        }
        catch {}
    }
}

function Add-LogEntry {
    param(
        $Window,
        [string]$Message
    )
    
    $logBox = $Window.FindName("LogTextBox")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logBox.AppendText("[$timestamp] $Message`r`n")
    $logBox.ScrollToEnd()
}

function Show-AgentDetails {
    param(
        $Window,
        $Agent
    )
    
    if (-not $Agent) { return }
    
    $panel = $Window.FindName("AgentDetailsPanel")
    $panel.Children.Clear()
    
    # Header
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = "🤖 $($Agent.Name)"
    $header.FontSize = 22
    $header.FontWeight = "Bold"
    $header.Foreground = "#007ACC"
    $header.Margin = "0,0,0,20"
    $panel.Children.Add($header)
    
    # Info Grid
    $grid = New-Object System.Windows.Controls.Grid
    
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = "Auto"
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = "*"
    $grid.ColumnDefinitions.Add($col1)
    $grid.ColumnDefinitions.Add($col2)
    
    $row = 0
    foreach ($prop in @('Type', 'Status', 'Level', 'Performance', 'Autonomy', 'ActionsCount')) {
        $rowDef = New-Object System.Windows.Controls.RowDefinition
        $rowDef.Height = "Auto"
        $grid.RowDefinitions.Add($rowDef)
        
        $label = New-Object System.Windows.Controls.TextBlock
        $label.Text = "${prop}:"
        $label.FontWeight = "Bold"
        $label.Margin = "0,5,20,5"
        [System.Windows.Controls.Grid]::SetRow($label, $row)
        [System.Windows.Controls.Grid]::SetColumn($label, 0)
        $grid.Children.Add($label)
        
        $value = New-Object System.Windows.Controls.TextBlock
        $valueText = $Agent.$prop
        if ($prop -in @('Performance', 'Autonomy')) {
            $valueText = $valueText.ToString('P2')
        }
        $value.Text = $valueText
        $value.Margin = "0,5,0,5"
        $value.Foreground = "#4EC9B0"
        [System.Windows.Controls.Grid]::SetRow($value, $row)
        [System.Windows.Controls.Grid]::SetColumn($value, 1)
        $grid.Children.Add($value)
        
        $row++
    }
    
    $panel.Children.Add($grid)
    
    # Skills Section
    if ($Agent.Skills) {
        $separator = New-Object System.Windows.Controls.Separator
        $separator.Margin = "0,20"
        $separator.Background = "#3F3F46"
        $panel.Children.Add($separator)
        
        $skillsHeader = New-Object System.Windows.Controls.TextBlock
        $skillsHeader.Text = "💡 SKILLS"
        $skillsHeader.FontSize = 16
        $skillsHeader.FontWeight = "Bold"
        $skillsHeader.Foreground = "#007ACC"
        $skillsHeader.Margin = "0,0,0,10"
        $panel.Children.Add($skillsHeader)
        
        foreach ($skillName in $Agent.Skills.PSObject.Properties.Name) {
            $skill = $Agent.Skills.$skillName
            
            $skillBorder = New-Object System.Windows.Controls.Border
            $skillBorder.Background = "#1E1E1E"
            $skillBorder.Padding = "10"
            $skillBorder.Margin = "0,5"
            $skillBorder.CornerRadius = 5
            
            $skillStack = New-Object System.Windows.Controls.StackPanel
            
            $nameText = New-Object System.Windows.Controls.TextBlock
            $nameText.Text = $skillName
            $nameText.FontWeight = "Bold"
            $nameText.FontSize = 14
            $skillStack.Children.Add($nameText)
            
            $statsText = New-Object System.Windows.Controls.TextBlock
            $statsText.Text = "Level $($skill.Level) • Experience: $($skill.Experience) • Success: $($skill.SuccessRate.ToString('P0'))"
            $statsText.Foreground = "#808080"
            $statsText.FontSize = 11
            $statsText.Margin = "0,5,0,0"
            $skillStack.Children.Add($statsText)
            
            $skillBorder.Child = $skillStack
            $panel.Children.Add($skillBorder)
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
#  CREATE AND SHOW WINDOW
# ═══════════════════════════════════════════════════════════════════

function Show-ControlCenter {
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    # Get controls
    $agentsList = $window.FindName("AgentsList")
    $btnRefresh = $window.FindName("BtnRefresh")
    $btnCreateAgent = $window.FindName("BtnCreateAgent")
    $btnTrainAgent = $window.FindName("BtnTrainAgent")
    $btnDeployAgent = $window.FindName("BtnDeployAgent")
    $btnQuickOrganize = $window.FindName("BtnQuickOrganize")
    $btnQuickCleanup = $window.FindName("BtnQuickCleanup")
    $btnQuickBackup = $window.FindName("BtnQuickBackup")
    $btnEvolution = $window.FindName("BtnEvolution")
    $btnClearLog = $window.FindName("BtnClearLog")
    $btnExecute = $window.FindName("BtnExecute")
    $commandInput = $window.FindName("CommandInput")
    
    # Initial load
    Update-AgentsList -ListBox $agentsList
    Update-Statistics -Window $window
    Update-PerformanceList -Window $window
    Add-LogEntry -Window $window -Message "Sistema Gene1799 avviato"
    
    # Event: Refresh
    $btnRefresh.Add_Click({
        Update-AgentsList -ListBox $agentsList
        Update-Statistics -Window $window
        Update-PerformanceList -Window $window
        Add-LogEntry -Window $window -Message "Dati aggiornati"
    })
    
    # Event: Agent selection
    $agentsList.Add_SelectionChanged({
        if ($agentsList.SelectedItem) {
            $selectedAgent = $agentsList.SelectedItem
            $agents = Get-AllAgentsForGUI
            $fullAgent = $agents | Where-Object {$_.Name -eq $selectedAgent.Name} | Select-Object -First 1
            Show-AgentDetails -Window $window -Agent $fullAgent
            
            # Switch to details tab
            $tabs = $window.FindName("MainTabs")
            $tabs.SelectedIndex = 1
        }
    })
    
    # Event: Create Agent
    $btnCreateAgent.Add_Click({
        Add-LogEntry -Window $window -Message "Apertura wizard creazione agente..."
        
        # Simple input dialog
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "Crea Nuovo Agente"
        $form.Size = New-Object System.Drawing.Size(400,250)
        $form.StartPosition = "CenterScreen"
        $form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
        $form.ForeColor = [System.Drawing.Color]::White
        
        $labelName = New-Object System.Windows.Forms.Label
        $labelName.Location = New-Object System.Drawing.Point(10,20)
        $labelName.Size = New-Object System.Drawing.Size(370,20)
        $labelName.Text = "Nome Agente:"
        $form.Controls.Add($labelName)
        
        $textName = New-Object System.Windows.Forms.TextBox
        $textName.Location = New-Object System.Drawing.Point(10,40)
        $textName.Size = New-Object System.Drawing.Size(360,20)
        $textName.BackColor = [System.Drawing.Color]::FromArgb(37,37,38)
        $textName.ForeColor = [System.Drawing.Color]::White
        $form.Controls.Add($textName)
        
        $labelType = New-Object System.Windows.Forms.Label
        $labelType.Location = New-Object System.Drawing.Point(10,70)
        $labelType.Size = New-Object System.Drawing.Size(370,20)
        $labelType.Text = "Tipo Agente:"
        $form.Controls.Add($labelType)
        
        $comboType = New-Object System.Windows.Forms.ComboBox
        $comboType.Location = New-Object System.Drawing.Point(10,90)
        $comboType.Size = New-Object System.Drawing.Size(360,20)
        $comboType.BackColor = [System.Drawing.Color]::FromArgb(37,37,38)
        $comboType.ForeColor = [System.Drawing.Color]::White
        $comboType.Items.AddRange(@('SOCIAL_MEDIA', 'FILE_MANAGER', 'DATA_ANALYST', 'CONTENT_CREATOR'))
        $comboType.SelectedIndex = 0
        $form.Controls.Add($comboType)
        
        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Location = New-Object System.Drawing.Point(200,160)
        $btnOK.Size = New-Object System.Drawing.Size(80,30)
        $btnOK.Text = "Crea"
        $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $btnOK.BackColor = [System.Drawing.Color]::FromArgb(0,122,204)
        $btnOK.ForeColor = [System.Drawing.Color]::White
        $btnOK.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $form.Controls.Add($btnOK)
        
        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Location = New-Object System.Drawing.Point(290,160)
        $btnCancel.Size = New-Object System.Drawing.Size(80,30)
        $btnCancel.Text = "Annulla"
        $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)
        $btnCancel.ForeColor = [System.Drawing.Color]::White
        $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $form.Controls.Add($btnCancel)
        
        $result = $form.ShowDialog()
        
        if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $textName.Text) {
            Add-LogEntry -Window $window -Message "Creazione agente $($textName.Text) in corso..."
            
            Start-Process powershell -ArgumentList "-NoExit", "-Command", "& 'D:\Gene1799\Explorer\gene1799_ai_agent_system.ps1' -Mode CREATE -AgentName '$($textName.Text)' -AgentType $($comboType.Text)"
        }
    })
    
    # Event: Train Agent
    $btnTrainAgent.Add_Click({
        if ($agentsList.SelectedItem) {
            $agentName = $agentsList.SelectedItem.Name
            Add-LogEntry -Window $window -Message "Avvio training per $agentName..."
            
            Start-Process powershell -ArgumentList "-NoExit", "-Command", "& 'D:\Gene1799\Explorer\gene1799_ai_agent_system.ps1' -Mode TRAIN -AgentName '$agentName' -TrainingCycles 20"
        }
        else {
            Add-LogEntry -Window $window -Message "⚠ Seleziona un agente prima"
        }
    })
    
    # Event: Deploy Agent
    $btnDeployAgent.Add_Click({
        if ($agentsList.SelectedItem) {
            $agentName = $agentsList.SelectedItem.Name
            Add-LogEntry -Window $window -Message "Deploy di $agentName in corso..."
            
            Start-Process powershell -ArgumentList "-NoExit", "-Command", "& 'D:\Gene1799\Explorer\gene1799_ai_agent_system.ps1' -Mode DEPLOY -AgentName '$agentName'"
        }
        else {
            Add-LogEntry -Window $window -Message "⚠ Seleziona un agente prima"
        }
    })
    
    # Event: Quick Actions
    $btnQuickOrganize.Add_Click({
        Add-LogEntry -Window $window -Message "🗂️ Organizzazione Downloads avviata..."
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& 'D:\Gene1799\Explorer\gene1799_file_manager.ps1' -Mode ORGANIZE"
    })
    
    $btnQuickCleanup.Add_Click({
        Add-LogEntry -Window $window -Message "🧹 Pulizia sistema avviata..."
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& 'D:\Gene1799\Explorer\gene1799_file_manager.ps1' -Mode CLEANUP"
    })
    
    $btnQuickBackup.Add_Click({
        Add-LogEntry -Window $window -Message "💾 Backup avviato..."
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& 'D:\Gene1799\Explorer\gene1799_file_manager.ps1' -Mode BACKUP"
    })
    
    $btnEvolution.Add_Click({
        Add-LogEntry -Window $window -Message "🧬 Evoluzione agenti in corso..."
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& 'D:\Gene1799\Explorer\gene1799_ai_agent_system.ps1' -Mode EVOLVE"
    })
    
    # Event: Clear Log
    $btnClearLog.Add_Click({
        $window.FindName("LogTextBox").Clear()
    })
    
    # Event: Execute Command
    $btnExecute.Add_Click({
        $cmd = $commandInput.Text
        if ($cmd -and $cmd -ne "Inserisci comando...") {
            Add-LogEntry -Window $window -Message "Esecuzione: $cmd"
            
            try {
                $result = Invoke-Expression $cmd
                Add-LogEntry -Window $window -Message "✓ Completato"
            }
            catch {
                Add-LogEntry -Window $window -Message "✗ Errore: $($_.Exception.Message)"
            }
            
            $commandInput.Clear()
        }
    })
    
    # Timer for auto-refresh
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(30)
    $timer.Add_Tick({
        Update-Statistics -Window $window
    })
    $timer.Start()
    
    # Show window
    $window.ShowDialog() | Out-Null
}

# ═══════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════

Clear-Host

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       GENE1799 DESKTOP MONITOR GUI - v1.0.0              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$Global:Gene1799Core.WriteLog.Invoke("🖥️ Avvio GUI Control Center...", "INFO")

Show-ControlCenter

$Global:Gene1799Core.WriteLog.Invoke("GUI chiusa", "INFO")
