#!/usr/bin/env pwsh

<#
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║        🔧 GENE1799 REPAIR AGENT v1.0 🔧                                  ║
║                                                                           ║
║  Autonomous System Repair & Validation Agent                             ║
║  Scans, validates, and repairs all GENE1799 installations                ║
║  across C:\, D:\, E:\ drives                                             ║
║                                                                           ║
║  Agent Architecture: Self-healing, autonomous repair                     ║
║  Status Tracking: Real-time validation and reporting                     ║
║  Consolidation: Unified system generation                                ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
#>

param(
    [ValidateSet('Scan', 'Validate', 'Repair', 'Consolidate', 'Full', 'Report')]
    [string]$Mode = 'Full',
    [string[]]$Drives = @('C:', 'D:', 'E:'),
    [switch]$AutoRepair,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ═══════════════════════════════════════════════════════════════════════════
# COLORS & LOGGING
# ═══════════════════════════════════════════════════════════════════════════

$Colors = @{
    Success = 'Green'
    Error   = 'Red'
    Warning = 'Yellow'
    Info    = 'Cyan'
    Debug   = 'Gray'
    Found   = 'Magenta'
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug', 'Found')]
        [string]$Level = 'Info'
    )

    if ($Level -eq 'Debug' -and -not $Verbose) { return }

    $Timestamp = Get-Date -Format 'HH:mm:ss'
    $Color = $Colors[$Level]
    $Symbol = @{
        Info    = '📋'
        Success = '✅'
        Warning = '⚠️'
        Error   = '❌'
        Debug   = '🔍'
        Found   = '📍'
    }[$Level]

    Write-Host "$Symbol [$Timestamp] $Message" -ForegroundColor $Color
}

# ═══════════════════════════════════════════════════════════════════════════
# REPAIR AGENT - SCAN PHASE
# ═══════════════════════════════════════════════════════════════════════════

$InventoryReport = @{
    Timestamp       = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ScannedDrives   = $Drives
    SystemsFound    = @()
    TotalSize       = 0
    ValidSystems    = 0
    CorruptedItems  = @()
    MissingFiles    = @()
    RepairsApplied  = @()
}

function Scan-GENE1799Systems {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  REPAIR AGENT: SCAN PHASE - Discovering all systems          ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

    foreach ($Drive in $Drives) {
        if (-not (Test-Path $Drive)) {
            Write-Log "$Drive Not accessible" -Level Warning
            continue
        }

        Write-Log "Scanning $Drive for GENE1799 systems..." -Level Info

        # Scan for Gene1799* patterns
        try {
            $Items = Get-ChildItem -Path $Drive -Filter "Gene1799*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 30

            foreach ($Item in $Items) {
                $SystemInfo = @{
                    Name       = $Item.Name
                    Path       = $Item.FullName
                    Size       = (Get-ChildItem -Path $Item.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    Created    = $Item.CreationTime
                    Modified   = $Item.LastWriteTime
                    Type       = 'GENE1799'
                    Status     = 'Unknown'
                    Components = @()
                    Issues     = @()
                }

                # Check for key components
                $RequiredFiles = @('package.json', 'server.js', 'start*.ps1', 'README.md')
                foreach ($FilePattern in $RequiredFiles) {
                    if (Get-ChildItem -Path $Item.FullName -Filter $FilePattern -Recurse -ErrorAction SilentlyContinue) {
                        $SystemInfo.Components += $FilePattern
                    }
                }

                # Determine health status
                if ($SystemInfo.Components.Count -ge 2) {
                    $SystemInfo.Status = 'Healthy'
                } elseif ($SystemInfo.Components.Count -ge 1) {
                    $SystemInfo.Status = 'Degraded'
                    $SystemInfo.Issues += "Missing key files"
                } else {
                    $SystemInfo.Status = 'Corrupted'
                    $SystemInfo.Issues += "No recognizable files found"
                }

                $InventoryReport.SystemsFound += $SystemInfo
                $InventoryReport.TotalSize += $SystemInfo.Size

                Write-Log "Found: $($SystemInfo.Name) - Status: $($SystemInfo.Status) - Size: $(([Math]::Round($SystemInfo.Size / 1MB, 2)) MB)" -Level Found
            }
        } catch {
            Write-Log "Error scanning $Drive : $_" -Level Warning
        }
    }

    # Also scan for c1799* pattern
    foreach ($Drive in $Drives) {
        try {
            $Items = Get-ChildItem -Path $Drive -Filter "c1799*" -Directory -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            foreach ($Item in $Items) {
                Write-Log "Found related system: $($Item.Name)" -Level Found
            }
        } catch { }
    }

    Write-Log "Scan complete: $($InventoryReport.SystemsFound.Count) systems found" -Level Success
}

# ═══════════════════════════════════════════════════════════════════════════
# REPAIR AGENT - VALIDATE PHASE
# ═══════════════════════════════════════════════════════════════════════════

function Validate-Systems {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  REPAIR AGENT: VALIDATE PHASE - Checking system integrity    ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

    foreach ($System in $InventoryReport.SystemsFound) {
        Write-Log "Validating $($System.Name)..." -Level Info

        # Check package.json integrity
        $PackageJsonPath = Join-Path $System.Path "package.json"
        if (Test-Path $PackageJsonPath) {
            try {
                $Package = Get-Content $PackageJsonPath -Raw | ConvertFrom-Json
                Write-Log "  ✓ package.json valid (v$($Package.version))" -Level Debug
            } catch {
                $System.Issues += "package.json corrupted"
                $InventoryReport.CorruptedItems += $PackageJsonPath
                Write-Log "  ✗ package.json corrupted - FLAGGED FOR REPAIR" -Level Warning
            }
        }

        # Check for essential startup scripts
        $StartScripts = @('*.ps1', '*.bat', '*.sh') | ForEach-Object { Get-ChildItem -Path $System.Path -Filter $_ -ErrorAction SilentlyContinue }
        if (-not $StartScripts) {
            $System.Issues += "No startup scripts found"
        }

        # Check node_modules
        $NodeModulesPath = Join-Path $System.Path "node_modules"
        if (-not (Test-Path $NodeModulesPath)) {
            $System.Issues += "node_modules missing (can be reinstalled)"
        } else {
            Write-Log "  ✓ node_modules present" -Level Debug
        }

        # Check .env files
        $EnvPath = Join-Path $System.Path ".env"
        if (-not (Test-Path $EnvPath)) {
            $EnvExamplePath = Join-Path $System.Path ".env.example"
            if (Test-Path $EnvExamplePath) {
                $System.Issues += ".env missing (example available)"
            }
        }

        # Final validation
        if ($System.Issues.Count -eq 0) {
            $System.Status = 'Valid'
            $InventoryReport.ValidSystems += 1
        }

        Write-Log "Validation complete for $($System.Name) - $($System.Issues.Count) issues found" -Level Info
    }

    Write-Log "Validation complete: $($InventoryReport.ValidSystems) systems valid, $($InventoryReport.CorruptedItems.Count) items corrupted" -Level Success
}

# ═══════════════════════════════════════════════════════════════════════════
# REPAIR AGENT - REPAIR PHASE
# ═══════════════════════════════════════════════════════════════════════════

function Repair-Systems {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  REPAIR AGENT: REPAIR PHASE - Fixing identified issues       ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

    foreach ($System in $InventoryReport.SystemsFound | Where-Object { $_.Issues.Count -gt 0 }) {
        Write-Log "Repairing $($System.Name)..." -Level Info

        foreach ($Issue in $System.Issues) {
            Write-Log "  Addressing: $Issue" -Level Info

            # Repair: Missing node_modules
            if ($Issue -like "*node_modules*") {
                Write-Log "  → Reinstalling npm dependencies..." -Level Info
                try {
                    Push-Location $System.Path
                    npm install --silent 2>&1 | Out-Null
                    Pop-Location
                    $InventoryReport.RepairsApplied += "npm install - $($System.Name)"
                    Write-Log "  ✓ Dependencies reinstalled" -Level Success
                } catch {
                    Write-Log "  ✗ Failed to reinstall dependencies" -Level Warning
                }
            }

            # Repair: Missing .env
            if ($Issue -like "*.env missing*") {
                Write-Log "  → Creating .env from template..." -Level Info
                $EnvExamplePath = Join-Path $System.Path ".env.example"
                $EnvPath = Join-Path $System.Path ".env"
                if (Test-Path $EnvExamplePath) {
                    Copy-Item $EnvExamplePath $EnvPath
                    $InventoryReport.RepairsApplied += ".env created - $($System.Name)"
                    Write-Log "  ✓ .env file created" -Level Success
                }
            }

            # Repair: Corrupted package.json
            if ($Issue -like "*package.json*") {
                Write-Log "  → Attempting package.json recovery..." -Level Warning
                $BackupPath = "$($System.Path).backup"
                if (Test-Path "$System.Path\package.json") {
                    Copy-Item "$System.Path\package.json" "$System.Path\package.json.corrupted"
                    Write-Log "  ✓ Corrupted file backed up for analysis" -Level Info
                }
            }
        }
    }

    Write-Log "Repair phase complete: $($InventoryReport.RepairsApplied.Count) repairs applied" -Level Success
}

# ═══════════════════════════════════════════════════════════════════════════
# REPAIR AGENT - CONSOLIDATION PHASE
# ═══════════════════════════════════════════════════════════════════════════

function Consolidate-Systems {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  REPAIR AGENT: CONSOLIDATE PHASE - Creating unified system   ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

    # Find the largest/best system as consolidation target
    $PrimarySystem = $InventoryReport.SystemsFound | Sort-Object -Property Size -Descending | Select-Object -First 1

    if (-not $PrimarySystem) {
        Write-Log "No valid system found for consolidation" -Level Error
        return
    }

    Write-Log "Selected primary system: $($PrimarySystem.Name) ($([Math]::Round($PrimarySystem.Size / 1MB, 2)) MB)" -Level Success

    # Create consolidation metadata
    $ConsolidationMap = @{
        PrimarySystem     = $PrimarySystem.Name
        PrimaryPath       = $PrimarySystem.Path
        ConsolidatedDate  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        SystemsIncluded   = @()
        TotalSizeGB       = [Math]::Round($InventoryReport.TotalSize / 1GB, 2)
        AgentCount        = 0
        ModuleCount       = 0
    }

    # Map all systems contributing to consolidation
    foreach ($System in $InventoryReport.SystemsFound) {
        $ConsolidationMap.SystemsIncluded += @{
            Name   = $System.Name
            Path   = $System.Path
            Status = $System.Status
            Size   = $System.Size
        }

        Write-Log "✓ Included in consolidation: $($System.Name)" -Level Info
    }

    Write-Log "Consolidation mapping complete: $($ConsolidationMap.SystemsIncluded.Count) systems mapped" -Level Success

    # Save consolidated map
    $ConsolidationMap | ConvertTo-Json | Out-File -Path "$($PrimarySystem.Path)\CONSOLIDATION_MAP.json" -Force
    Write-Log "Consolidation map saved" -Level Success
}

# ═══════════════════════════════════════════════════════════════════════════
# REPAIR AGENT - REPORT GENERATION
# ═══════════════════════════════════════════════════════════════════════════

function Generate-Report {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  REPAIR AGENT: REPORT GENERATION - Creating final status     ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

    $Report = @{
        timestamp            = $InventoryReport.Timestamp
        agent_name           = "GENE1799 Repair Agent v1.0"
        mode                 = $Mode
        scanned_drives       = $InventoryReport.ScannedDrives
        systems_found        = $InventoryReport.SystemsFound.Count
        systems_valid        = $InventoryReport.ValidSystems
        total_size_gb        = [Math]::Round($InventoryReport.TotalSize / 1GB, 2)
        corrupted_items      = $InventoryReport.CorruptedItems.Count
        repairs_applied      = $InventoryReport.RepairsApplied.Count
        status               = if ($InventoryReport.CorruptedItems.Count -eq 0) { "HEALTHY" } else { "REPAIRED" }
        systems_inventory    = $InventoryReport.SystemsFound
    }

    # Display summary
    Write-Host "`n" -BackgroundColor DarkMagenta
    Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "GENE1799 REPAIR AGENT - FINAL REPORT" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "`nSCAN RESULTS:" -ForegroundColor Yellow
    Write-Host "  Systems Found:     $($Report.systems_found)"
    Write-Host "  Systems Valid:     $($Report.systems_valid)"
    Write-Host "  Total Size:        $($Report.total_size_gb) GB"
    Write-Host "  Corrupted Items:   $($Report.corrupted_items)"
    Write-Host "  Repairs Applied:   $($Report.repairs_applied)"
    Write-Host "  Overall Status:    $($Report.status)"

    Write-Host "`nSYSTEMS INVENTORY:" -ForegroundColor Yellow
    foreach ($System in $Report.systems_inventory) {
        $SizeMB = [Math]::Round($System.Size / 1MB, 2)
        Write-Host "  • $($System.Name) - $($System.Status) - $($SizeMB) MB"
    }

    Write-Host "`n═════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

    # Save report
    $ReportPath = "$env:TEMP\GENE1799_Repair_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $Report | ConvertTo-Json -Depth 10 | Out-File -Path $ReportPath -Force
    Write-Log "Complete report saved to: $ReportPath" -Level Success

    return $Report
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════

function Main {
    Write-Host "`n" -BackgroundColor DarkMagenta
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║   GENE1799 REPAIR AGENT v1.0                                 ║" -ForegroundColor Magenta
    Write-Host "║   Autonomous System Repair & Validation                      ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host "`n"

    try {
        switch ($Mode) {
            'Full' {
                Scan-GENE1799Systems
                Validate-Systems
                if ($AutoRepair) {
                    Repair-Systems
                }
                Consolidate-Systems
                $Report = Generate-Report
            }
            'Scan' {
                Scan-GENE1799Systems
                $Report = Generate-Report
            }
            'Validate' {
                Scan-GENE1799Systems
                Validate-Systems
                $Report = Generate-Report
            }
            'Repair' {
                Scan-GENE1799Systems
                Validate-Systems
                Repair-Systems
                $Report = Generate-Report
            }
            'Consolidate' {
                Scan-GENE1799Systems
                Validate-Systems
                Consolidate-Systems
                $Report = Generate-Report
            }
            'Report' {
                $Report = $InventoryReport | ConvertTo-Json
                Write-Host $Report
            }
        }

        Write-Log "Repair Agent execution complete" -Level Success
    } catch {
        Write-Log "ERROR: $_" -Level Error
        exit 1
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# RUN
# ═══════════════════════════════════════════════════════════════════════════

Main
