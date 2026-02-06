# ╔══════════════════════════════════════════════════════════════════╗
# ║  GENE1799 COMPLETE FIX SCRIPT - ADVANCED VERSION                 ║
# ║  Risolve: op_Addition, Python PATH, Dashboard Port, GeneBus      ║
# ╚══════════════════════════════════════════════════════════════════╝

Write-Host "`n🔧 GENE1799 ADVANCED FIX - DIAGNOSTIC & REPAIR" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════════
# [1/6] FIX OP_ADDITION BUG - ADVANCED METHOD
# ═══════════════════════════════════════════════════════════════════
Write-Host "[1/6] Fixing op_Addition bug (Advanced Method)..." -ForegroundColor Yellow

$scannerPath = "D:\Gene1799\modules\Gene1799AgentScanner\Gene1799AgentScanner.psm1"

if (Test-Path $scannerPath) {
    # Backup con timestamp
    $backupPath = "${scannerPath}.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $scannerPath $backupPath -Force
    Write-Host "   📦 Backup creato: $backupPath" -ForegroundColor Cyan
    
    # Leggi il contenuto
    $content = Get-Content $scannerPath -Raw
    
    # DIAGNOSTIC: Trova tutte le occorrenze del problema
    $pattern = '\$registeredCount\s*=\s*\$registeredCount\s*\+\s*1'
    $matches = [regex]::Matches($content, $pattern)
    Write-Host "   🔍 Trovate $($matches.Count) occorrenze del bug" -ForegroundColor Cyan
    
    if ($matches.Count -eq 0) {
        # Prova pattern alternativi
        $altPatterns = @(
            '\$registeredCount\s*\+=\s*1',
            '\$registeredCount\+\+',
            'registeredCount\s*=\s*registeredCount\s*\+\s*1'
        )
        
        foreach ($altPattern in $altPatterns) {
            $altMatches = [regex]::Matches($content, $altPattern)
            if ($altMatches.Count -gt 0) {
                Write-Host "   ⚠️ Pattern alternativo trovato: $altPattern ($($altMatches.Count) volte)" -ForegroundColor Yellow
            }
        }
    }
    
    # FIX MULTIPLI: Prova tutte le possibili varianti del bug
    $fixes = @{
        '\$registeredCount\s*=\s*\$registeredCount\s*\+\s*1' = '[int]$registeredCount = [int]$registeredCount + 1'
        'registeredCount\s*=\s*registeredCount\s*\+\s*1' = '[int]$registeredCount = [int]$registeredCount + 1'
        '\$registeredCount\s*=\s*\(\$registeredCount\s*\+\s*1\)' = '[int]$registeredCount = [int]$registeredCount + 1'
    }
    
    $fixCount = 0
    foreach ($pattern in $fixes.Keys) {
        $newContent = $content -replace $pattern, $fixes[$pattern]
        if ($newContent -ne $content) {
            $content = $newContent
            $fixCount++
            Write-Host "   ✅ Fix applicato: $pattern" -ForegroundColor Green
        }
    }
    
    if ($fixCount -gt 0) {
        Set-Content -Path $scannerPath -Value $content -Encoding UTF8
        Write-Host "   ✅ File aggiornato con $fixCount fix!" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Nessun pattern trovato - verificare manualmente il file" -ForegroundColor Yellow
        Write-Host "   📄 File: $scannerPath" -ForegroundColor Cyan
        
        # Mostra le righe sospette
        $lines = Get-Content $scannerPath
        $lineNum = 0
        foreach ($line in $lines) {
            $lineNum++
            if ($line -match 'registeredCount') {
                Write-Host "   Riga $lineNum : $line" -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Host "   ❌ File non trovato: $scannerPath" -ForegroundColor Red
}

# ═══════════════════════════════════════════════════════════════════
# [2/6] PYTHON PATH DISCOVERY & CONFIGURATION
# ═══════════════════════════════════════════════════════════════════
Write-Host "`n[2/6] Discovering Python installation..." -ForegroundColor Yellow

$pythonPaths = @(
    "C:\Python312",
    "C:\Python311",
    "C:\Python310",
    "C:\Program Files\Python312",
    "C:\Program Files\Python311",
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python312",
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python311"
)

$foundPython = $null
foreach ($path in $pythonPaths) {
    if (Test-Path "$path\python.exe") {
        $foundPython = $path
        Write-Host "   ✅ Python trovato: $foundPython" -ForegroundColor Green
        
        # Aggiungi al PATH
        if ($env:PATH -notlike "*$foundPython*") {
            $env:PATH = "$foundPython;$foundPython\Scripts;$env:PATH"
            Write-Host "   ✅ Python aggiunto al PATH" -ForegroundColor Green
        }
        
        # Verifica versione
        $version = & "$foundPython\python.exe" --version 2>&1
        Write-Host "   📊 Versione: $version" -ForegroundColor Cyan
        break
    }
}

if (-not $foundPython) {
    Write-Host "   ⚠️ Python NON trovato in nessuna posizione standard" -ForegroundColor Yellow
    Write-Host "   💡 Suggerimento: Cerca manualmente con 'where.exe python'" -ForegroundColor Cyan
    
    # Prova a trovare Python con where.exe
    try {
        $wherePython = where.exe python 2>$null | Select-Object -First 1
        if ($wherePython) {
            $foundPython = Split-Path -Parent $wherePython
            Write-Host "   ✅ Python trovato con where.exe: $foundPython" -ForegroundColor Green
            $env:PATH = "$foundPython;$foundPython\Scripts;$env:PATH"
        }
    } catch {
        Write-Host "   ⚠️ where.exe fallito - Python probabilmente non installato" -ForegroundColor Yellow
    }
}

# ═══════════════════════════════════════════════════════════════════
# [3/6] DASHBOARD PORT MANAGEMENT
# ═══════════════════════════════════════════════════════════════════
Write-Host "`n[3/6] Managing Dashboard Port 18002..." -ForegroundColor Yellow

# Trova tutti i processi sulla porta 18002
$connections = Get-NetTCPConnection -LocalPort 18002 -ErrorAction SilentlyContinue

if ($connections) {
    Write-Host "   🔍 Trovate $($connections.Count) connessioni sulla porta 18002" -ForegroundColor Cyan
    
    foreach ($conn in $connections) {
        $processId = $conn.OwningProcess
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        
        if ($process) {
            Write-Host "   📊 Processo: $($process.Name) (PID: $processId)" -ForegroundColor Cyan
            
            # Non tentare di killare System (PID 4) o altri processi critici
            if ($processId -eq 4 -or $process.Name -eq "System") {
                Write-Host "   ⚠️ Processo di sistema - NON terminabile" -ForegroundColor Yellow
                Write-Host "   💡 Usa porta alternativa: -DashboardPort 18003" -ForegroundColor Cyan
            } else {
                try {
                    Stop-Process -Id $processId -Force -ErrorAction Stop
                    Write-Host "   ✅ Processo terminato: $($process.Name)" -ForegroundColor Green
                } catch {
                    Write-Host "   ❌ Impossibile terminare: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
} else {
    Write-Host "   ✅ Porta 18002 libera" -ForegroundColor Green
}

# Suggerisci porte alternative
Write-Host "   💡 Porte alternative consigliate: 18003, 18004, 19000" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════════
# [4/6] MODULE RELOAD WITH VALIDATION
# ═══════════════════════════════════════════════════════════════════
Write-Host "`n[4/6] Reloading modules with validation..." -ForegroundColor Yellow

$modules = @(
    @{Name="Gene1799Core"; Path="D:\Gene1799\modules\Gene1799Core\Gene1799Core.psd1"},
    @{Name="Gene1799Orchestrator"; Path="D:\Gene1799\modules\Gene1799Orchestrator\Gene1799Orchestrator.psd1"},
    @{Name="Gene1799AgentScanner"; Path="D:\Gene1799\modules\Gene1799AgentScanner\Gene1799AgentScanner.psd1"},
    @{Name="Gene1799Extensions"; Path="D:\Gene1799\modules\Gene1799Extensions\Gene1799Extensions.psd1"},
    @{Name="Gene1799Bus"; Path="D:\Gene1799\modules\Gene1799Bus\Gene1799Bus.psd1"}
)

foreach ($module in $modules) {
    if (Test-Path $module.Path) {
        try {
            # Rimuovi se già caricato
            if (Get-Module $module.Name) {
                Remove-Module $module.Name -Force -ErrorAction SilentlyContinue
            }
            
            # Importa
            Import-Module $module.Path -Force -ErrorAction Stop
            Write-Host "   ✅ $($module.Name) caricato" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ $($module.Name) ERRORE: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "   ⚠️ $($module.Name) - File non trovato: $($module.Path)" -ForegroundColor Yellow
    }
}

# ═══════════════════════════════════════════════════════════════════
# [5/6] SYSTEM STARTUP WITH ERROR HANDLING
# ═══════════════════════════════════════════════════════════════════
Write-Host "`n[5/6] Starting Gene1799 System..." -ForegroundColor Yellow

# Start Core
try {
    Start-Gene1799Core -Root 'D:\Gene1799' -LoadAgents -ErrorAction Stop | Out-Null
    Write-Host "   ✅ Gene1799Core avviato" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Gene1799Core ERRORE: $($_.Exception.Message)" -ForegroundColor Red
}

# Start Orchestrator con porta alternativa se necessario
$dashboardPort = 18003  # Usa porta alternativa per evitare conflitti

try {
    Start-Gene1799Orchestrator -ScanAndRegister -StartDashboard -DashboardPort $dashboardPort -ErrorAction Stop | Out-Null
    Write-Host "   ✅ Orchestrator + Dashboard avviati (porta $dashboardPort)" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Orchestrator ERRORE: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   💡 Prova manualmente: Start-Gene1799Orchestrator -DashboardPort 19000" -ForegroundColor Cyan
}

# Start Auto-Learning
try {
    Start-GeneAutoLearning -BusRoot "D:\Gene1799" -SystemId "Gene1799Hub" -ErrorAction Stop | Out-Null
    Write-Host "   ✅ Auto-Learning avviato" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Auto-Learning ERRORE: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════════
# [6/6] FINAL STATUS & VERIFICATION
# ═══════════════════════════════════════════════════════════════════
Write-Host "`n[6/6] Final Status & Verification..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Test op_Addition fix
Write-Host "🧪 TEST 1: Verifica op_Addition fix..." -ForegroundColor Cyan
$testScan = Invoke-Gene1799AgentScan -AutoRegister 2>&1
$opAdditionErrors = ($testScan | Select-String "op_Addition").Count

if ($opAdditionErrors -eq 0) {
    Write-Host "   ✅ PASS: Nessun errore op_Addition!" -ForegroundColor Green
} else {
    Write-Host "   ❌ FAIL: Trovati $opAdditionErrors errori op_Addition" -ForegroundColor Red
    Write-Host "   💡 Azione manuale richiesta - vedi sezione MANUAL FIX sotto" -ForegroundColor Yellow
}

# Test Python
Write-Host "`n🧪 TEST 2: Verifica Python..." -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>&1
    Write-Host "   ✅ PASS: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ FAIL: Python non trovato nel PATH" -ForegroundColor Red
}

# Test Auto-Learning
Write-Host "`n🧪 TEST 3: Verifica Auto-Learning..." -ForegroundColor Cyan
try {
    $status = Get-GeneAutoLearningStatus
    Write-Host "   ✅ PASS: Auto-Learning status recuperato" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ WARN: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test Dashboard
Write-Host "`n🧪 TEST 4: Verifica Dashboard..." -ForegroundColor Cyan
$testPorts = @(18002, 18003, 18004)
foreach ($port in $testPorts) {
    $conn = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($conn) {
        Write-Host "   ✅ Dashboard attiva su porta $port" -ForegroundColor Green
        Write-Host "   🌐 URL: http://localhost:$port/" -ForegroundColor Cyan
        break
    }
}

# Test Registered Agents
Write-Host "`n🧪 TEST 5: Verifica Agenti Registrati..." -ForegroundColor Cyan
try {
    $agents = Get-Gene1799RegisteredAgents
    Write-Host "   ✅ PASS: $($agents.Count) agenti registrati" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ WARN: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════════
# SUMMARY & MANUAL FIX INSTRUCTIONS
# ═══════════════════════════════════════════════════════════════════
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  GENE1799 FIX COMPLETED                                   ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

if ($opAdditionErrors -gt 0) {
    Write-Host "⚠️ MANUAL FIX REQUIRED - op_Addition Bug" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "Il file AgentScanner contiene ancora il bug. Esegui questo fix manuale:`n" -ForegroundColor White
    Write-Host "1. Apri: $scannerPath" -ForegroundColor Cyan
    Write-Host "2. Cerca tutte le righe con: " -NoNewline -ForegroundColor Cyan
    Write-Host "`$registeredCount = `$registeredCount + 1" -ForegroundColor Yellow
    Write-Host "3. Sostituisci con: " -NoNewline -ForegroundColor Cyan
    Write-Host "[int]`$registeredCount = [int]`$registeredCount + 1" -ForegroundColor Green
    Write-Host "4. Salva e ricarica: " -NoNewline -ForegroundColor Cyan
    Write-Host "Import-Module '$scannerPath' -Force`n" -ForegroundColor Green
}

Write-Host "📋 QUICK REFERENCE COMMANDS:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Dashboard:      http://localhost:$dashboardPort/" -ForegroundColor White
Write-Host "  Status:         Get-Gene1799Status" -ForegroundColor White
Write-Host "  Learning:       Get-GeneAutoLearningStatus" -ForegroundColor White
Write-Host "  Agents:         Get-Gene1799RegisteredAgents" -ForegroundColor White
Write-Host "  Bus Stats:      Get-GeneBusStats -BusRoot 'D:\Gene1799' -SystemId 'Gene1799Hub'" -ForegroundColor White
Write-Host "  Scan Agents:    Invoke-Gene1799AgentScan" -ForegroundColor White
Write-Host ""
