# ═══════════════════════════════════════════════════════════
# 🖥️ GENE1799 DESKTOP MONITOR GUI v2.0
# Applicazione WPF per monitoraggio completo sistema
# ═══════════════════════════════════════════════════════════

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Importa configurazione
if (Test-Path ".\gene1799_ai_integration_core.ps1") {
    . .\gene1799_ai_integration_core.ps1 -Mode STATUS | Out-Null
}

# ═══════════════════════════════════════════════════════════
# XAML UI DEFINITION
# ═══════════════════════════════════════════════════════════

[xml]$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="🧠 GENE1799 AI MONITORING DASHBOARD" 
    Height="900" 
    Width="1400"
    WindowStartupLocation="CenterScreen"
    Background="#1E1E1E"
    ResizeMode="CanResize">
    
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontFamily" Value="Consolas"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3E3E42"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="Border">
            <Setter Property="BorderBrush" Value="#3E3E42"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="5"/>
            <Setter Property="Padding" Value="10"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="60"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="30"/>
        </Grid.RowDefinitions>
        
        <!-- HEADER -->
        <Border Grid.Row="0" Background="#252526" BorderThickness="0,0,0,2">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Orientation="Vertical" VerticalAlignment="Center" Margin="15,0">
                    <TextBlock Text="🧠 GENE1799 AI MONITORING DASHBOARD" FontSize="20" FontWeight="Bold" Foreground="#00D4FF"/>
                    <TextBlock x:Name="txtSystemTime" Text="System Time: Loading..." FontSize="11" Foreground="#888888" Margin="0,2,0,0"/>
                </StackPanel>
                
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,15,0">
                    <Button x:Name="btnRefresh" Content="🔄 Refresh" Width="100"/>
                    <Button x:Name="btnSettings" Content="⚙️ Settings" Width="100"/>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- MAIN CONTENT -->
        <TabControl Grid.Row="1" Background="#2D2D30" BorderThickness="0" Margin="0">
            
            <!-- TAB: OVERVIEW -->
            <TabItem Header="📊 Overview" FontSize="14">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <Grid Margin="10">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        
                        <!-- DISK STATUS -->
                        <Border Grid.Row="0" Background="#252526">
                            <StackPanel>
                                <TextBlock Text="💾 MULTI-DISK ARCHITECTURE" FontSize="16" FontWeight="Bold" Foreground="#00D4FF" Margin="0,0,0,10"/>
                                
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    
                                    <!-- Disk C -->
                                    <Border Grid.Column="0" Background="#1E1E1E" Margin="5">
                                        <StackPanel>
                                            <TextBlock Text="C: AI CORE" FontSize="14" FontWeight="Bold" Foreground="#4EC9B0"/>
                                            <TextBlock x:Name="txtDiskC" Text="Status: Loading..." Margin="0,5"/>
                                            <ProgressBar x:Name="pbDiskC" Height="20" Margin="0,5" Foreground="#4EC9B0"/>
                                        </StackPanel>
                                    </Border>
                                    
                                    <!-- Disk D -->
                                    <Border Grid.Column="1" Background="#1E1E1E" Margin="5">
                                        <StackPanel>
                                            <TextBlock Text="D: GENE1799 CORE" FontSize="14" FontWeight="Bold" Foreground="#DCDCAA"/>
                                            <TextBlock x:Name="txtDiskD" Text="Status: Loading..." Margin="0,5"/>
                                            <ProgressBar x:Name="pbDiskD" Height="20" Margin="0,5" Foreground="#DCDCAA"/>
                                        </StackPanel>
                                    </Border>
                                    
                                    <!-- Disk E -->
                                    <Border Grid.Column="2" Background="#1E1E1E" Margin="5">
                                        <StackPanel>
                                            <TextBlock Text="E: AI EXTENDED" FontSize="14" FontWeight="Bold" Foreground="#C586C0"/>
                                            <TextBlock x:Name="txtDiskE" Text="Status: Loading..." Margin="0,5"/>
                                            <ProgressBar x:Name="pbDiskE" Height="20" Margin="0,5" Foreground="#C586C0"/>
                                        </StackPanel>
                                    </Border>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <!-- AI PROVIDERS STATUS -->
                        <Border Grid.Row="1" Background="#252526" Margin="0,10,0,0">
                            <StackPanel>
                                <TextBlock Text="🔌 AI PROVIDERS STATUS" FontSize="16" FontWeight="Bold" Foreground="#00D4FF" Margin="0,0,0,10"/>
                                <ListBox x:Name="lstProviders" Background="#1E1E1E" Foreground="White" BorderThickness="0" Height="150"/>
                            </StackPanel>
                        </Border>
                        
                        <!-- SYSTEM METRICS -->
                        <Border Grid.Row="2" Background="#252526" Margin="0,10,0,0">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                
                                <StackPanel Grid.Column="0" Margin="0,0,10,0">
                                    <TextBlock Text="💻 SYSTEM RESOURCES" FontSize="16" FontWeight="Bold" Foreground="#00D4FF" Margin="0,0,0,10"/>
                                    <TextBlock x:Name="txtCPU" Text="CPU: 0%" Margin="0,5"/>
                                    <ProgressBar x:Name="pbCPU" Height="15" Foreground="#CE9178" Margin="0,2,0,10"/>
                                    <TextBlock x:Name="txtRAM" Text="RAM: 0 GB / 0 GB" Margin="0,5"/>
                                    <ProgressBar x:Name="pbRAM" Height="15" Foreground="#569CD6" Margin="0,2"/>
                                </StackPanel>
                                
                                <StackPanel Grid.Column="1" Margin="10,0,0,0">
                                    <TextBlock Text="📈 QUICK STATS" FontSize="16" FontWeight="Bold" Foreground="#00D4FF" Margin="0,0,0,10"/>
                                    <TextBlock x:Name="txtTotalAgents" Text="Total Agents: 0" Margin="0,5"/>
                                    <TextBlock x:Name="txtActiveAgents" Text="Active Agents: 0" Margin="0,5"/>
                                    <TextBlock x:Name="txtTrainedAgents" Text="Trained Agents: 0" Margin="0,5"/>
                                    <TextBlock x:Name="txtTotalTasks" Text="Tasks Completed: 0" Margin="0,5"/>
                                </StackPanel>
                            </Grid>
                        </Border>
                    </Grid>
                </ScrollViewer>
            </TabItem>
            
            <!-- TAB: AGENTS -->
            <TabItem Header="🤖 AI Agents" FontSize="14">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="#252526" Margin="10,10,10,5">
                        <StackPanel>
                            <TextBlock Text="🤖 ACTIVE AI AGENTS" FontSize="16" FontWeight="Bold" Foreground="#00D4FF"/>
                            <TextBlock x:Name="txtAgentCount" Text="0 agents registered" FontSize="12" Foreground="#888888" Margin="0,5"/>
                        </StackPanel>
                    </Border>
                    
                    <ListBox x:Name="lstAgents" Grid.Row="1" Background="#1E1E1E" Foreground="White" BorderThickness="0" Margin="10,5" ScrollViewer.VerticalScrollBarVisibility="Auto"/>
                    
                    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="10">
                        <Button x:Name="btnCreateAgent" Content="➕ Create Agent" Width="130"/>
                        <Button x:Name="btnTrainAgent" Content="🧠 Train Agent" Width="130"/>
                        <Button x:Name="btnExecuteAgent" Content="▶️ Execute" Width="130"/>
                    </StackPanel>
                </Grid>
            </TabItem>
            
            <!-- TAB: LOGS -->
            <TabItem Header="📝 System Logs" FontSize="14">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="#252526" Margin="10,10,10,5">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="📝 SYSTEM LOGS" FontSize="16" FontWeight="Bold" Foreground="#00D4FF" VerticalAlignment="Center"/>
                            <Button x:Name="btnClearLogs" Content="🗑️ Clear" Width="80" Margin="20,0,0,0"/>
                            <Button x:Name="btnExportLogs" Content="💾 Export" Width="80"/>
                        </StackPanel>
                    </Border>
                    
                    <TextBox x:Name="txtLogs" Grid.Row="1" Background="#1E1E1E" Foreground="#CCCCCC" FontFamily="Consolas" FontSize="11" 
                             IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" Margin="10,5" Padding="10"/>
                    
                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="10">
                        <TextBlock Text="🔄 Auto-refresh: " Foreground="#888888" VerticalAlignment="Center"/>
                        <CheckBox x:Name="chkAutoRefresh" Content="Enabled" IsChecked="True" Foreground="White" VerticalAlignment="Center" Margin="5,0"/>
                    </StackPanel>
                </Grid>
            </TabItem>
            
            <!-- TAB: NETWORK -->
            <TabItem Header="🌐 Network" FontSize="14">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="#252526">
                        <TextBlock Text="🌐 SYNAPTIC NETWORK CONNECTIONS" FontSize="16" FontWeight="Bold" Foreground="#00D4FF"/>
                    </Border>
                    
                    <Canvas x:Name="canvasNetwork" Grid.Row="1" Background="#1E1E1E" Margin="0,10,0,0"/>
                </Grid>
            </TabItem>
            
        </TabControl>
        
        <!-- STATUS BAR -->
        <Border Grid.Row="2" Background="#007ACC" BorderThickness="0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <TextBlock x:Name="txtStatusBar" Grid.Column="0" Text="Ready" VerticalAlignment="Center" Margin="10,0" FontWeight="Bold"/>
                <TextBlock x:Name="txtConnectionStatus" Grid.Column="1" Text="● ONLINE" Foreground="#4EC9B0" VerticalAlignment="Center" Margin="10,0" FontWeight="Bold"/>
                <TextBlock Grid.Column="2" Text="v2.0" VerticalAlignment="Center" Margin="10,0"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# ═══════════════════════════════════════════════════════════
# LOAD XAML
# ═══════════════════════════════════════════════════════════

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$txtSystemTime = $window.FindName("txtSystemTime")
$txtDiskC = $window.FindName("txtDiskC")
$txtDiskD = $window.FindName("txtDiskD")
$txtDiskE = $window.FindName("txtDiskE")
$pbDiskC = $window.FindName("pbDiskC")
$pbDiskD = $window.FindName("pbDiskD")
$pbDiskE = $window.FindName("pbDiskE")
$lstProviders = $window.FindName("lstProviders")
$txtCPU = $window.FindName("txtCPU")
$pbCPU = $window.FindName("pbCPU")
$txtRAM = $window.FindName("txtRAM")
$pbRAM = $window.FindName("pbRAM")
$txtTotalAgents = $window.FindName("txtTotalAgents")
$txtActiveAgents = $window.FindName("txtActiveAgents")
$txtTrainedAgents = $window.FindName("txtTrainedAgents")
$txtTotalTasks = $window.FindName("txtTotalTasks")
$txtAgentCount = $window.FindName("txtAgentCount")
$lstAgents = $window.FindName("lstAgents")
$txtLogs = $window.FindName("txtLogs")
$txtStatusBar = $window.FindName("txtStatusBar")
$txtConnectionStatus = $window.FindName("txtConnectionStatus")
$btnRefresh = $window.FindName("btnRefresh")
$btnSettings = $window.FindName("btnSettings")
$btnCreateAgent = $window.FindName("btnCreateAgent")
$btnTrainAgent = $window.FindName("btnTrainAgent")
$btnExecuteAgent = $window.FindName("btnExecuteAgent")
$btnClearLogs = $window.FindName("btnClearLogs")
$btnExportLogs = $window.FindName("btnExportLogs")
$chkAutoRefresh = $window.FindName("chkAutoRefresh")
$canvasNetwork = $window.FindName("canvasNetwork")

# ═══════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════

function Update-SystemTime {
    $txtSystemTime.Text = "System Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

function Update-DiskInfo {
    # Disk C:
    if (Test-Path "C:\") {
        try {
            $driveC = Get-PSDrive C -ErrorAction SilentlyContinue
            if ($driveC) {
                $usedC = $driveC.Used / 1GB
                $freeC = $driveC.Free / 1GB
                $totalC = $usedC + $freeC
                $percentC = [math]::Round(($usedC / $totalC) * 100, 1)
                
                $txtDiskC.Text = "✓ ONLINE`nUsed: $([math]::Round($usedC, 1)) GB / $([math]::Round($totalC, 1)) GB"
                $pbDiskC.Value = $percentC
            }
        } catch {
            $txtDiskC.Text = "⚠️ Error reading disk"
        }
    } else {
        $txtDiskC.Text = "✗ OFFLINE"
    }
    
    # Disk D:
    if (Test-Path "D:\") {
        try {
            $driveD = Get-PSDrive D -ErrorAction SilentlyContinue
            if ($driveD) {
                $usedD = $driveD.Used / 1GB
                $freeD = $driveD.Free / 1GB
                $totalD = $usedD + $freeD
                $percentD = [math]::Round(($usedD / $totalD) * 100, 1)
                
                $txtDiskD.Text = "✓ ONLINE`nUsed: $([math]::Round($usedD, 1)) GB / $([math]::Round($totalD, 1)) GB"
                $pbDiskD.Value = $percentD
            }
        } catch {
            $txtDiskD.Text = "⚠️ Error reading disk"
        }
    } else {
        $txtDiskD.Text = "✗ OFFLINE"
    }
    
    # Disk E:
    if (Test-Path "E:\") {
        try {
            $driveE = Get-PSDrive E -ErrorAction SilentlyContinue
            if ($driveE) {
                $usedE = $driveE.Used / 1GB
                $freeE = $driveE.Free / 1GB
                $totalE = $usedE + $freeE
                $percentE = [math]::Round(($usedE / $totalE) * 100, 1)
                
                $txtDiskE.Text = "✓ ONLINE`nUsed: $([math]::Round($usedE, 1)) GB / $([math]::Round($totalE, 1)) GB"
                $pbDiskE.Value = $percentE
            }
        } catch {
            $txtDiskE.Text = "⚠️ Error reading disk"
        }
    } else {
        $txtDiskE.Text = "✗ OFFLINE"
    }
}

function Update-Providers {
    $lstProviders.Items.Clear()
    
    Load-APIKeys | Out-Null
    
    foreach ($providerName in $Global:AIProviders.Keys | Sort-Object) {
        $provider = $Global:AIProviders[$providerName]
        
        $statusIcon = switch($provider.Status) {
            "ONLINE" { "🟢" }
            "CONFIGURED" { "🟡" }
            "OFFLINE" { "🔴" }
            "NOT_CONFIGURED" { "⚪" }
            default { "⚫" }
        }
        
        $item = "$statusIcon $($provider.Name.PadRight(25)) | Status: $($provider.Status.PadRight(15)) | Models: $($provider.Models.Count)"
        $lstProviders.Items.Add($item)
    }
}

function Update-SystemMetrics {
    # CPU
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
    if ($cpu) {
        $cpuPercent = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
        $txtCPU.Text = "CPU: $cpuPercent%"
        $pbCPU.Value = $cpuPercent
    }
    
    # RAM
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = $totalRAM - $freeRAM
    $ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
    
    $txtRAM.Text = "RAM: $usedRAM GB / $totalRAM GB"
    $pbRAM.Value = $ramPercent
}

function Update-AgentStats {
    $dbPath = $Global:Gene1799Config.AgentDB
    
    if (Test-Path $dbPath) {
        $db = Get-Content $dbPath | ConvertFrom-Json
        
        $total = if ($db.agents) { $db.agents.Count } else { 0 }
        $trained = if ($db.agents) { ($db.agents | Where-Object { $_.status -eq "TRAINED" }).Count } else { 0 }
        $active = if ($db.agents) { ($db.agents | Where-Object { $_.status -eq "ACTIVE" }).Count } else { 0 }
        
        $txtTotalAgents.Text = "Total Agents: $total"
        $txtActiveAgents.Text = "Active Agents: $active"
        $txtTrainedAgents.Text = "Trained Agents: $trained"
        
        # TODO: Calculate total tasks from performance metrics
        $txtTotalTasks.Text = "Tasks Completed: 0"
    } else {
        $txtTotalAgents.Text = "Total Agents: 0"
        $txtActiveAgents.Text = "Active Agents: 0"
        $txtTrainedAgents.Text = "Trained Agents: 0"
        $txtTotalTasks.Text = "Tasks Completed: 0"
    }
}

function Update-AgentsList {
    $lstAgents.Items.Clear()
    
    $dbPath = $Global:Gene1799Config.AgentDB
    
    if (Test-Path $dbPath) {
        $db = Get-Content $dbPath | ConvertFrom-Json
        
        if ($db.agents -and $db.agents.Count -gt 0) {
            $txtAgentCount.Text = "$($db.agents.Count) agents registered"
            
            foreach ($agent in $db.agents) {
                $statusIcon = switch($agent.status) {
                    "TRAINED" { "🟢" }
                    "INITIALIZED" { "🟡" }
                    "ACTIVE" { "🟢" }
                    default { "⚪" }
                }
                
                $item = "$statusIcon $($agent.name.PadRight(20)) | Type: $($agent.type.PadRight(15)) | Accuracy: $($agent.learning_system.accuracy)% | XP: $($agent.learning_system.experience_points)"
                $lstAgents.Items.Add($item)
            }
        } else {
            $txtAgentCount.Text = "No agents registered"
            $lstAgents.Items.Add("No agents created yet. Use 'Create Agent' button.")
        }
    } else {
        $txtAgentCount.Text = "Database not found"
        $lstAgents.Items.Add("Agent database not initialized.")
    }
}

function Update-Logs {
    if (Test-Path $Global:Gene1799Config.LogFile) {
        $logs = Get-Content $Global:Gene1799Config.LogFile -Tail 100 -ErrorAction SilentlyContinue
        if ($logs) {
            $txtLogs.Text = $logs -join "`n"
            $txtLogs.ScrollToEnd()
        }
    } else {
        $txtLogs.Text = "No logs available yet."
    }
}

function Refresh-AllData {
    $txtStatusBar.Text = "Refreshing data..."
    
    Update-SystemTime
    Update-DiskInfo
    Update-Providers
    Update-SystemMetrics
    Update-AgentStats
    Update-AgentsList
    Update-Logs
    
    $txtStatusBar.Text = "Ready - Last refresh: $(Get-Date -Format 'HH:mm:ss')"
}

# ═══════════════════════════════════════════════════════════
# EVENT HANDLERS
# ═══════════════════════════════════════════════════════════

$btnRefresh.Add_Click({
    Refresh-AllData
})

$btnSettings.Add_Click({
    [System.Windows.MessageBox]::Show("Settings panel coming soon!", "Settings", "OK", "Information")
})

$btnCreateAgent.Add_Click({
    # Launch agent creation window
    $result = [System.Windows.MessageBox]::Show("Launch agent creation wizard?`n`nThis will open the PowerShell script for creating agents.", "Create Agent", "YesNo", "Question")
    if ($result -eq "Yes") {
        Start-Process powershell -ArgumentList "-NoExit", "-File", ".\gene1799_ai_agent_system.ps1", "-Mode", "CREATE"
    }
})

$btnTrainAgent.Add_Click({
    $selected = $lstAgents.SelectedItem
    if ($selected) {
        # Extract agent name from selected item
        $agentName = ($selected -split '\|')[0].Trim() -replace '^[🟢🟡⚪🔴]\s*', ''
        $result = [System.Windows.MessageBox]::Show("Train agent: $agentName ?", "Train Agent", "YesNo", "Question")
        if ($result -eq "Yes") {
            Start-Process powershell -ArgumentList "-NoExit", "-File", ".\gene1799_ai_agent_system.ps1", "-Mode", "TRAIN", "-AgentName", $agentName
        }
    } else {
        [System.Windows.MessageBox]::Show("Please select an agent first", "Train Agent", "OK", "Warning")
    }
})

$btnExecuteAgent.Add_Click({
    $selected = $lstAgents.SelectedItem
    if ($selected) {
        $agentName = ($selected -split '\|')[0].Trim() -replace '^[🟢🟡⚪🔴]\s*', ''
        [System.Windows.MessageBox]::Show("Agent execution interface coming soon!`n`nAgent: $agentName", "Execute Agent", "OK", "Information")
    } else {
        [System.Windows.MessageBox]::Show("Please select an agent first", "Execute Agent", "OK", "Warning")
    }
})

$btnClearLogs.Add_Click({
    $result = [System.Windows.MessageBox]::Show("Clear all logs?", "Clear Logs", "YesNo", "Warning")
    if ($result -eq "Yes") {
        $txtLogs.Text = "Logs cleared at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
})

$btnExportLogs.Add_Click({
    if (Test-Path $Global:Gene1799Config.LogFile) {
        $exportPath = "D:\Gene1799\Logs\exported_logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        Copy-Item $Global:Gene1799Config.LogFile $exportPath
        [System.Windows.MessageBox]::Show("Logs exported to:`n$exportPath", "Export Complete", "OK", "Information")
    }
})

# ═══════════════════════════════════════════════════════════
# AUTO-REFRESH TIMER
# ═══════════════════════════════════════════════════════════

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(5)
$timer.Add_Tick({
    if ($chkAutoRefresh.IsChecked) {
        Update-SystemTime
        Update-SystemMetrics
        Update-Logs
    }
})
$timer.Start()

# ═══════════════════════════════════════════════════════════
# INITIAL DATA LOAD
# ═══════════════════════════════════════════════════════════

Refresh-AllData

# ═══════════════════════════════════════════════════════════
# SHOW WINDOW
# ═══════════════════════════════════════════════════════════

$window.ShowDialog() | Out-Null
