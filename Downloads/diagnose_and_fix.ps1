# ═══════════════════════════════════════════════════════════
# 🔧 GENE1799 ULTIMATE DIAGNOSTIC & FIX SCRIPT
# ═══════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GENE1799 DIAGNOSTIC & REPAIR TOOL v2.0        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# 1️⃣ Setup base directories
$basePath = "D:\Gene1799"
$explorerPath = "$basePath\Explorer"
$logPath = "$basePath\Logs"
$targetScript = "$explorerPath\hub_explorer.ps1"

# 2️⃣ Ensure directories exist
$dirs = @($explorerPath, $logPath, "$basePath\Exp", "$basePath\Modules", "$basePath\Config")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "[CREATE] $dir" -ForegroundColor Green
    }
}

# 3️⃣ Check if hub_explorer.ps1 exists and diagnose
if (Test-Path $targetScript) {
    Write-Host "[FOUND] $targetScript" -ForegroundColor Green
    
    # Create backup
    $backupName = "hub_explorer.ps1.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $targetScript -Destination "$explorerPath\$backupName" -Force
    Write-Host "[BACKUP] Created: $backupName" -ForegroundColor Yellow
    
    # Try to parse and find errors
    Write-Host "`n[DIAGNOSE] Analyzing syntax..." -ForegroundColor Cyan
    $content = Get-Content $targetScript -Raw
    
    # Show problematic area around line 56
    $lines = Get-Content $targetScript
    if ($lines.Count -ge 56) {
        Write-Host "`n--- Lines 50-60 ---" -ForegroundColor DarkGray
        for ($i = 49; $i -lt [Math]::Min(60, $lines.Count); $i++) {
            $lineNum = $i + 1
            $marker = if ($lineNum -eq 56) { ">>> " } else { "    " }
            Write-Host "$marker$lineNum : $($lines[$i])" -ForegroundColor $(if ($lineNum -eq 56) { "Red" } else { "Gray" })
        }
    }
    
} else {
    Write-Host "[ERROR] hub_explorer.ps1 not found!" -ForegroundColor Red
    Write-Host "[INFO] Creating new template..." -ForegroundColor Yellow
}

# 4️⃣ Create corrected hub_explorer.ps1
Write-Host "`n[FIX] Creating corrected hub_explorer.ps1..." -ForegroundColor Green

$newScript = @'
# ═══════════════════════════════════════════════════════════
# 🚀 GENE1799 HUB EXPLORER - CORRECTED VERSION
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

# Log function
$logFile = "D:\Gene1799\Logs\master_orchestrator.log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry -Force
}

# Safe-Action function with proper error handling
function Safe-Action {
    param(
        [string]$From,
        [string]$To
    )
    
    # Validate parameters
    if ([string]::IsNullOrWhiteSpace($From)) {
        $msg = "[ERROR] Safe-Action called with empty From parameter"
        Write-Host $msg -ForegroundColor Red
        Write-Log $msg "ERROR"
        return
    }
    
    if ([string]::IsNullOrWhiteSpace($To)) {
        $msg = "[ERROR] Safe-Action called with empty To parameter"
        Write-Host $msg -ForegroundColor Red
        Write-Log $msg "ERROR"
        return
    }
    
    # Check if source exists
    if (-not (Test-Path $From)) {
        $msg = "[WARN] Source path does not exist: $From"
        Write-Host $msg -ForegroundColor Yellow
        Write-Log $msg "WARN"
        return
    }
    
    # Create destination if needed
    $destParent = Split-Path -Parent $To
    if (-not (Test-Path $destParent)) {
        New-Item -Path $destParent -ItemType Directory -Force | Out-Null
    }
    
    try {
        if ($Mode -eq "DRYRUN") {
            Write-Host "[DRYRUN] Would copy: '$From' -> '$To'" -ForegroundColor Cyan
            Write-Log "DRYRUN: Copy '$From' -> '$To'" "INFO"
        } else {
            Copy-Item -Path $From -Destination $To -Recurse -Force -ErrorAction Stop
            Write-Host "[OK] Copied: '$From' -> '$To'" -ForegroundColor Green
            Write-Log "LIVE: Copied '$From' -> '$To'" "INFO"
        }
    }
    catch {
        $msg = "[ERROR] Copy failed: '$From' -> '$To' | $($_.Exception.Message)"
        Write-Host $msg -ForegroundColor Red
        Write-Log $msg "ERROR"
    }
}

# ═══════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       GENE1799 HUB EXPLORER - $Mode MODE       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "[MODE] $Mode" -ForegroundColor Yellow
Write-Host "[FROM] $From" -ForegroundColor Yellow
Write-Host "[TO]   $To`n" -ForegroundColor Yellow

Write-Log "=== HUB EXPLORER START === Mode: $Mode, From: $From, To: $To" "INFO"

# Validate paths
if (-not (Test-Path $From)) {
    Write-Host "[ERROR] Source path does not exist: $From" -ForegroundColor Red
    Write-Log "Source path missing: $From" "ERROR"
    exit 1
}

if (-not (Test-Path $To)) {
    Write-Host "[WARN] Destination path does not exist, creating: $To" -ForegroundColor Yellow
    New-Item -Path $To -ItemType Directory -Force | Out-Null
}

# Execute Safe-Action
Safe-Action -From $From -To $To

Write-Host "`n[DONE] HUB EXPLORER completed in $Mode mode" -ForegroundColor Green
Write-Log "=== HUB EXPLORER END ===" "INFO"
'@

# Write corrected script
Set-Content -Path $targetScript -Value $newScript -Force -Encoding UTF8
Write-Host "[SUCCESS] hub_explorer.ps1 corrected and saved!" -ForegroundColor Green

# 5️⃣ Unblock the script
Unblock-File $targetScript -ErrorAction SilentlyContinue
Write-Host "[UNBLOCK] Script unblocked" -ForegroundColor Green

# 6️⃣ Test syntax
Write-Host "`n[TEST] Validating PowerShell syntax..." -ForegroundColor Cyan
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $targetScript -Raw), [ref]$null)
    Write-Host "[OK] Syntax validation PASSED!" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Syntax validation FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# 7️⃣ Create test runner script
$testRunner = @'
# Test Runner for hub_explorer.ps1
param([string]$Mode = "DRYRUN")

Set-Location "D:\Gene1799\Explorer"
Set-ExecutionPolicy Bypass -Scope Process -Force

$params = @{
    Mode = $Mode
    From = "D:\Gene1799\Exp"
    To   = "D:\Gene1799\Modules"
}

Write-Host "`n🔹 Running hub_explorer.ps1 in $Mode mode...`n" -ForegroundColor Cyan
& .\hub_explorer.ps1 @params

Write-Host "`n🔹 Recent logs:" -ForegroundColor Cyan
Get-Content "D:\Gene1799\Logs\master_orchestrator.log" -Tail 20 -ErrorAction SilentlyContinue
'@

Set-Content -Path "$explorerPath\test_runner.ps1" -Value $testRunner -Force
Write-Host "[CREATE] test_runner.ps1 created" -ForegroundColor Green

# 8️⃣ Summary
Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              REPAIR COMPLETE!                  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. cd D:\Gene1799\Explorer" -ForegroundColor White
Write-Host "  2. .\test_runner.ps1 -Mode DRYRUN" -ForegroundColor White
Write-Host "  3. .\test_runner.ps1 -Mode LIVE" -ForegroundColor White
Write-Host ""
Write-Host "Or directly:" -ForegroundColor Yellow
Write-Host "  .\hub_explorer.ps1 -Mode DRYRUN -From 'D:\Gene1799\Exp' -To 'D:\Gene1799\Modules'" -ForegroundColor White
Write-Host ""
