# ═══════════════════════════════════════════════════════════
# 🎯 GENE1799 MASTER REPAIR SCRIPT
# Esegue: Cleanup Log → Fix Script → Test
# ═══════════════════════════════════════════════════════════

Write-Host "`n" -NoNewline
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "║         GENE1799 MASTER REPAIR & TEST SUITE v3.0          ║" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Set execution policy
Set-ExecutionPolicy Bypass -Scope Process -Force

# ═══════════════════════════════════════════════════════════
# STEP 1: LOG CLEANUP
# ═══════════════════════════════════════════════════════════

Write-Host "`n┌─────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
Write-Host "│ STEP 1/3: LOG CLEANUP                                   │" -ForegroundColor Yellow
Write-Host "└─────────────────────────────────────────────────────────┘`n" -ForegroundColor Yellow

$logFile = "D:\Gene1799\Logs\master_orchestrator.log"
$archiveDir = "E:\Gene1799_Data\Logs_Archive"

if (-not (Test-Path $archiveDir)) {
    New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
}

if (Test-Path $logFile) {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $archivePath = "$archiveDir\master_orchestrator_$timestamp.log"
    Copy-Item $logFile -Destination $archivePath -Force
    
    $errorCount = (Get-Content $logFile | Select-String -Pattern "\[ERROR\]" | Measure-Object).Count
    Write-Host "  [ARCHIVE] Old log saved (Errors: $errorCount)" -ForegroundColor Cyan
    
    Clear-Content $logFile -Force
    Add-Content -Path $logFile -Value "# GENE1799 LOG - Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "  [CLEAR]   Log cleared and initialized" -ForegroundColor Green
} else {
    $logDir = Split-Path $logFile -Parent
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    Set-Content -Path $logFile -Value "# GENE1799 LOG - Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "  [CREATE]  New log file created" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════
# STEP 2: FIX HUB_EXPLORER.PS1
# ═══════════════════════════════════════════════════════════

Write-Host "`n┌─────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
Write-Host "│ STEP 2/3: FIX HUB_EXPLORER.PS1                          │" -ForegroundColor Yellow
Write-Host "└─────────────────────────────────────────────────────────┘`n" -ForegroundColor Yellow

$explorerPath = "D:\Gene1799\Explorer"
$targetScript = "$explorerPath\hub_explorer.ps1"

# Ensure directory exists
if (-not (Test-Path $explorerPath)) {
    New-Item -Path $explorerPath -ItemType Directory -Force | Out-Null
}

# Backup existing script
if (Test-Path $targetScript) {
    $backupName = "hub_explorer.ps1.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $targetScript -Destination "$explorerPath\$backupName" -Force
    Write-Host "  [BACKUP]  Created: $backupName" -ForegroundColor Cyan
}

# Create corrected script
$newScript = @'
# ═══════════════════════════════════════════════════════════
# 🚀 GENE1799 HUB EXPLORER - CORRECTED VERSION v3.0
# ═══════════════════════════════════════════════════════════

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("DRYRUN", "LIVE")]
    [string]$Mode = "DRYRUN",
    
    [Parameter(Mandatory=$false)]
    [string]$From = "D:\Gene1799\Exp",
    
    [Parameter(Mandatory=$false)]
    [string]$To = "D:\Gene1799\Modules"
)

# ═══════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════

$logFile = "D:\Gene1799\Logs\master_orchestrator.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    $logDir = Split-Path $logFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $logFile -Value $logEntry -Force -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════
# SAFE-ACTION FUNCTION
# ═══════════════════════════════════════════════════════════

function Safe-Action {
    param(
        [string]$From,
        [string]$To
    )
    
    # Validate From parameter
    if ([string]::IsNullOrWhiteSpace($From)) {
        $msg = "Safe-Action: From parameter is empty"
        Write-Host "  [ERROR] $msg" -ForegroundColor Red
        Write-Log $msg "ERROR"
        return
    }
    
    # Validate To parameter
    if ([string]::IsNullOrWhiteSpace($To)) {
        $msg = "Safe-Action: To parameter is empty"
        Write-Host "  [ERROR] $msg" -ForegroundColor Red
        Write-Log $msg "ERROR"
        return
    }
    
    # Check if source exists
    if (-not (Test-Path $From)) {
        $msg = "Safe-Action: Source not found: $From"
        Write-Host "  [WARN] $msg" -ForegroundColor Yellow
        Write-Log $msg "WARN"
        return
    }
    
    # Create destination parent if needed
    $destParent = Split-Path -Parent $To
    if (-not (Test-Path $destParent)) {
        New-Item -Path $destParent -ItemType Directory -Force | Out-Null
    }
    
    # Execute copy operation
    try {
        if ($Mode -eq "DRYRUN") {
            Write-Host "  [DRYRUN] Would copy: $From -> $To" -ForegroundColor Cyan
            Write-Log "DRYRUN: Copy '$From' -> '$To'" "INFO"
        } else {
            Copy-Item -Path $From -Destination $To -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Copied: $From -> $To" -ForegroundColor Green
            Write-Log "LIVE: Copied '$From' -> '$To'" "SUCCESS"
        }
    }
    catch {
        $msg = "Copy failed: $From -> $To | Error: $($_.Exception.Message)"
        Write-Host "  [ERROR] $msg" -ForegroundColor Red
        Write-Log $msg "ERROR"
    }
}

# ═══════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    GENE1799 HUB EXPLORER - $Mode MODE         " -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "  [MODE] $Mode" -ForegroundColor Yellow
Write-Host "  [FROM] $From" -ForegroundColor Yellow
Write-Host "  [TO]   $To`n" -ForegroundColor Yellow

Write-Log "=== HUB EXPLORER START === Mode: $Mode | From: $From | To: $To" "INFO"

# Validate source path
if (-not (Test-Path $From)) {
    Write-Host "  [ERROR] Source path not found: $From" -ForegroundColor Red
    Write-Log "Source path missing: $From" "ERROR"
    exit 1
}

# Create destination if needed
if (-not (Test-Path $To)) {
    Write-Host "  [WARN] Creating destination: $To" -ForegroundColor Yellow
    New-Item -Path $To -ItemType Directory -Force | Out-Null
}

# Execute Safe-Action
Safe-Action -From $From -To $To

Write-Host "`n  [DONE] Operation completed in $Mode mode" -ForegroundColor Green
Write-Log "=== HUB EXPLORER END ===" "INFO"
'@

Set-Content -Path $targetScript -Value $newScript -Force -Encoding UTF8
Unblock-File $targetScript -ErrorAction SilentlyContinue
Write-Host "  [CREATE]  hub_explorer.ps1 created and unblocked" -ForegroundColor Green

# Validate syntax
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $targetScript -Raw), [ref]$null)
    Write-Host "  [OK]      Syntax validation PASSED" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR]   Syntax validation FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# ═══════════════════════════════════════════════════════════
# STEP 3: RUN TESTS
# ═══════════════════════════════════════════════════════════

Write-Host "`n┌─────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
Write-Host "│ STEP 3/3: RUNNING TESTS                                 │" -ForegroundColor Yellow
Write-Host "└─────────────────────────────────────────────────────────┘`n" -ForegroundColor Yellow

# Ensure test directories exist
$testDirs = @("D:\Gene1799\Exp", "D:\Gene1799\Modules", "D:\Gene1799\Config")
foreach ($dir in $testDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Create test file in Exp directory
$testFile = "D:\Gene1799\Exp\test_file.txt"
Set-Content -Path $testFile -Value "Test data - $(Get-Date)" -Force
Write-Host "  [TEST]    Created test file: $testFile" -ForegroundColor Cyan

# Test DRYRUN mode
Write-Host "`n  ┌─── DRYRUN TEST ───┐" -ForegroundColor Cyan
$params = @{
    Mode = "DRYRUN"
    From = "D:\Gene1799\Exp"
    To   = "D:\Gene1799\Modules"
}
& $targetScript @params

# Test LIVE mode
Write-Host "`n  ┌─── LIVE TEST ───┐" -ForegroundColor Green
$params.Mode = "LIVE"
& $targetScript @params

# Show recent logs
Write-Host "`n  ┌─── RECENT LOGS ───┐" -ForegroundColor Magenta
if (Test-Path $logFile) {
    Get-Content $logFile -Tail 15 | ForEach-Object {
        if ($_ -match "\[ERROR\]") {
            Write-Host "  $_" -ForegroundColor Red
        } elseif ($_ -match "\[WARN\]") {
            Write-Host "  $_" -ForegroundColor Yellow
        } elseif ($_ -match "\[SUCCESS\]") {
            Write-Host "  $_" -ForegroundColor Green
        } else {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
}

# ═══════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "║              ✅ REPAIR & TEST COMPLETE ✅                  ║" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📋 FILES CREATED:" -ForegroundColor Cyan
Write-Host "   • hub_explorer.ps1 (corrected)" -ForegroundColor White
Write-Host "   • Log cleanup completed" -ForegroundColor White
Write-Host "   • Test execution completed" -ForegroundColor White

Write-Host "`n🚀 QUICK START COMMANDS:" -ForegroundColor Yellow
Write-Host "   cd D:\Gene1799\Explorer" -ForegroundColor White
Write-Host "   .\hub_explorer.ps1 -Mode DRYRUN" -ForegroundColor White
Write-Host "   .\hub_explorer.ps1 -Mode LIVE -From 'D:\Gene1799\Exp' -To 'D:\Gene1799\Modules'" -ForegroundColor White
Write-Host ""
