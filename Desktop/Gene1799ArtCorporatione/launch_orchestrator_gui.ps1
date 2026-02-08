#!/usr/bin/env pwsh
<#
.SYNOPSIS
Gene1799 Orchestrator GUI Launcher - PowerShell Edition
Advanced launcher with visual feedback and dependency checking

.DESCRIPTION
Launches the Gene1799 Orchestrator GUI with comprehensive validation,
GPU detection, and system optimization recommendations.

.EXAMPLE
.\launch_orchestrator_gui.ps1
#>

# Colors for output
$Colors = @{
    Success = 'Green'
    Error = 'Red'
    Warning = 'Yellow'
    Info = 'Cyan'
    Header = 'Blue'
    Accent = 'Magenta'
}

function Write-Banner {
    param([string]$Message)
    Write-Host ""
    Write-Host "╔" + ("═" * 68) + "╗" -ForegroundColor $Colors.Header
    Write-Host "║ $Message" + (" " * (66 - $Message.Length)) + "║" -ForegroundColor $Colors.Header
    Write-Host "╚" + ("═" * 68) + "╝" -ForegroundColor $Colors.Header
    Write-Host ""
}

function Write-Status {
    param([string]$Message, [string]$Status = "OK")
    if ($Status -eq "OK") {
        Write-Host "  [✓] $Message" -ForegroundColor $Colors.Success
    } elseif ($Status -eq "WARN") {
        Write-Host "  [⚠] $Message" -ForegroundColor $Colors.Warning
    } else {
        Write-Host "  [✗] $Message" -ForegroundColor $Colors.Error
    }
}

function Check-Python {
    try {
        $version = python --version 2>&1
        Write-Status "Python found: $version" "OK"
        return $true
    } catch {
        Write-Status "Python not found!" "ERROR"
        return $false
    }
}

function Check-GPU {
    try {
        $gpu = nvidia-smi --query-gpu=name --format=csv,noheader 2>$null | Select-Object -First 1
        if ($gpu) {
            Write-Status "NVIDIA GPU detected: $gpu" "OK"
            return $true
        } else {
            Write-Status "No NVIDIA GPU detected (CPU mode)" "WARN"
            return $false
        }
    } catch {
        Write-Status "GPU detection unavailable (CPU mode)" "WARN"
        return $false
    }
}

function Check-Dependencies {
    Write-Host "`n📦 Checking Python dependencies..." -ForegroundColor $Colors.Info
    
    $packages = @('psutil', 'pynvml')
    
    foreach ($package in $packages) {
        try {
            python -c "import $package" 2>$null
            Write-Status "Package installed: $package" "OK"
        } catch {
            Write-Status "Installing $package..." "WARN"
            python -m pip install $package -q
            Write-Status "Installed: $package" "OK"
        }
    }
}

function Check-Orchestrator {
    $orchestratorPath = Join-Path (Get-Location) "orchestrator_fixed.py"
    $guiPath = Join-Path (Get-Location) "orchestrator_gui.py"
    
    if (!(Test-Path $orchestratorPath)) {
        Write-Status "Orchestrator not found: $orchestratorPath" "ERROR"
        return $false
    }
    
    if (!(Test-Path $guiPath)) {
        Write-Status "GUI not found: $guiPath" "ERROR"
        return $false
    }
    
    Write-Status "Orchestrator found: $orchestratorPath" "OK"
    Write-Status "GUI found: $guiPath" "OK"
    return $true
}

function Get-SystemInfo {
    Write-Host "`n🖥️  System Information:" -ForegroundColor $Colors.Info
    
    $cpuCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    $ramMB = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1MB
    $osVersion = (Get-CimInstance Win32_OperatingSystem).Caption
    
    Write-Status "OS: $osVersion" "OK"
    Write-Status "CPU Cores: $cpuCount" "OK"
    Write-Status "Memory: $([math]::Round($ramMB/1024, 1)) GB" "OK"
}

function Start-OrchestratorGUI {
    Write-Banner "🎼 GENE1799 ORCHESTRATOR GUI - STARTING"
    
    Write-Host "`n🔍 Pre-launch validation..." -ForegroundColor $Colors.Info
    
    # Check Python
    if (!(Check-Python)) {
        Write-Host "`nError: Python is required!" -ForegroundColor $Colors.Error
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Get system info
    Get-SystemInfo
    
    # Check GPU
    Write-Host "`n🎮 GPU Acceleration:" -ForegroundColor $Colors.Info
    $gpuAvailable = Check-GPU
    
    # Check dependencies
    Check-Dependencies
    
    # Check orchestrator files
    Write-Host "`n📄 Component Validation:" -ForegroundColor $Colors.Info
    if (!(Check-Orchestrator)) {
        Write-Host "`nError: Required files not found!" -ForegroundColor $Colors.Error
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # All checks passed
    Write-Banner "✓ ALL CHECKS PASSED - LAUNCHING GUI"
    
    Write-Host "GPU Acceleration: $(if ($gpuAvailable) { 'ENABLED' } else { 'CPU MODE' })" -ForegroundColor $(if ($gpuAvailable) { $Colors.Success } else { $Colors.Warning })
    Write-Host "Starting in 3 seconds..." -ForegroundColor $Colors.Info
    
    Start-Sleep -Seconds 3
    
    Write-Host "`n▶️  Launching Gene1799 Orchestrator GUI..." -ForegroundColor $Colors.Header
    
    try {
        python "orchestrator_gui.py"
    } catch {
        Write-Host "`nError launching GUI: $_" -ForegroundColor $Colors.Error
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Main execution
Write-Banner "GENE1799 ORCHESTRATOR - GPU ACCELERATED GUI"

Write-Host "PowerShell v" + $PSVersionTable.PSVersion.Major + "." + $PSVersionTable.PSVersion.Minor -ForegroundColor $Colors.Info
Write-Host "Windows PowerShell - Advanced Launcher" -ForegroundColor $Colors.Info

# Change to project directory if needed
$projectDir = $PSScriptRoot
if ($projectDir) {
    Set-Location $projectDir
}

# Launch GUI
Start-OrchestratorGUI

Write-Host "`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - GUI closed" -ForegroundColor $Colors.Info
Write-Host "Thank you for using Gene1799 Orchestrator!" -ForegroundColor $Colors.Success

exit 0
