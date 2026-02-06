# ╔══════════════════════════════════════════════════════════════════╗
# ║  GENE1799 AGENTSCANNER - DIRECT PATCH FOR OP_ADDITION BUG       ║
# ╚══════════════════════════════════════════════════════════════════╝

$scannerPath = "D:\Gene1799\modules\Gene1799AgentScanner\Gene1799AgentScanner.psm1"

Write-Host "🔧 DIRECT PATCH - Gene1799AgentScanner op_Addition Fix`n" -ForegroundColor Cyan

if (-not (Test-Path $scannerPath)) {
    Write-Host "❌ File non trovato: $scannerPath" -ForegroundColor Red
    exit 1
}

# Backup
$backupPath = "${scannerPath}.backup_$(Get-Date -Format 'yyyyMMddHHmmss')"
Copy-Item $scannerPath $backupPath -Force
Write-Host "✅ Backup creato: $backupPath`n" -ForegroundColor Green

# Leggi il file riga per riga
$lines = Get-Content $scannerPath
$fixedLines = @()
$fixCount = 0

Write-Host "🔍 Scansione file...`n" -ForegroundColor Cyan

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $lineNum = $i + 1
    
    # Identifica tutte le varianti del bug
    $patterns = @(
        @{
            Pattern = '^\s*\$registeredCount\s*=\s*\$registeredCount\s*\+\s*1\s*$'
            Replacement = '        [int]$registeredCount = [int]$registeredCount + 1'
        },
        @{
            Pattern = '^\s*registeredCount\s*=\s*registeredCount\s*\+\s*1\s*$'
            Replacement = '        [int]$registeredCount = [int]$registeredCount + 1'
        },
        @{
            Pattern = '^\s*\$registeredCount\s*=\s*\(\$registeredCount\s*\+\s*1\)\s*$'
            Replacement = '        [int]$registeredCount = [int]$registeredCount + 1'
        }
    )
    
    $wasFixed = $false
    foreach ($p in $patterns) {
        if ($line -match $p.Pattern) {
            Write-Host "Riga $lineNum (PRIMA):  $line" -ForegroundColor Yellow
            $line = $p.Replacement
            Write-Host "Riga $lineNum (DOPO):   $line" -ForegroundColor Green
            Write-Host ""
            $fixCount++
            $wasFixed = $true
            break
        }
    }
    
    $fixedLines += $line
}

if ($fixCount -gt 0) {
    # Salva il file corretto
    Set-Content -Path $scannerPath -Value $fixedLines -Encoding UTF8
    Write-Host "✅ File patchato con successo!" -ForegroundColor Green
    Write-Host "   Fix applicati: $fixCount" -ForegroundColor Cyan
    Write-Host "   Backup: $backupPath`n" -ForegroundColor Cyan
    
    Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "1. Ricarica il modulo:" -ForegroundColor White
    Write-Host "   Import-Module '$scannerPath' -Force`n" -ForegroundColor Yellow
    Write-Host "2. Testa la scansione:" -ForegroundColor White
    Write-Host "   Invoke-Gene1799AgentScan -AutoRegister`n" -ForegroundColor Yellow
    Write-Host "3. Verifica nessun errore op_Addition`n" -ForegroundColor White
    
} else {
    Write-Host "⚠️ NESSUNA correzione necessaria!" -ForegroundColor Yellow
    Write-Host "   Il file potrebbe essere già corretto o il pattern non corrisponde.`n" -ForegroundColor Cyan
    
    Write-Host "🔍 RICERCA MANUALE:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Cerco tutte le righe contenenti 'registeredCount'...`n" -ForegroundColor White
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'registeredCount') {
            $lineNum = $i + 1
            Write-Host "Riga $lineNum : $($lines[$i])" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "`n💡 SUGGERIMENTO:" -ForegroundColor Cyan
    Write-Host "Se vedi righe come:" -ForegroundColor White
    Write-Host "  `$registeredCount = `$registeredCount + 1" -ForegroundColor Yellow
    Write-Host "Modificale manualmente in:" -ForegroundColor White
    Write-Host "  [int]`$registeredCount = [int]`$registeredCount + 1`n" -ForegroundColor Green
}

Write-Host "════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
