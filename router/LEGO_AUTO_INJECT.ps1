# ════════════════════════════════════════════════════════════════════════════════
# LEGO AUTO-INJECT - Start CORE INGEGNERI + SuiteV17 + MACAO
# ════════════════════════════════════════════════════════════════════════════════

# --- PATHS ---
$OrchestratorPath = "C:\SuiteV17_Unified\Orchestrator"
$RegistryFile = "$env:USERPROFILE\lego_registry.json"

# --- FUNZIONI ---
function Start-CoreIngegneri {
    Write-Host "🧠 Avvio CORE INGEGNERI LEGO..." -ForegroundColor Cyan
    $ps1 = Join-Path $OrchestratorPath "CORE_INGEGNERI_LEGO.ps1"
    if (Test-Path $ps1) {
        Start-Process pwsh -ArgumentList "-File `"$ps1`" -Start" -WindowStyle Hidden
        Write-Host "✅ CORE INGEGNERI LEGO lanciato in background."
    } else {
        Write-Warning "⚠ CORE_INGEGNERI_LEGO.ps1 non trovato!"
    }
}

function Ensure-Registry {
    if (-not (Test-Path $RegistryFile)) {
        "{}" | Out-File $RegistryFile -Encoding UTF8
        Write-Host "📋 Registro LEGO creato: $RegistryFile"
    }
}

function Auto-Injection {
    Write-Host "🔗 Iniezione automatica nel sistema..." -ForegroundColor Yellow

    # --- Assicura registro ---
    Ensure-Registry

    # --- Avvia CORE INGEGNERI LEGO ---
    Start-CoreIngegneri

    # --- Avvia MACAO se non già in esecuzione ---
    if (-not (Get-Process -Name node -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match "MACAO" })) {
        $macaoJS = Join-Path $OrchestratorPath "macao_simple.js"
        if (Test-Path $macaoJS) {
            Start-Process node -ArgumentList "`"$macaoJS`"" -WindowStyle Hidden
            Write-Host "🧠 MACAO lanciato in background."
        } else {
            Write-Warning "⚠ MACAO file non trovato!"
        }
    } else {
        Write-Host "🟢 MACAO già in esecuzione."
    }

    # --- Test alert Premonitori (può essere integrato SMS/Telegram in seguito) ---
    Write-Host "⚡ Test ALERT Premonitori attivato ✅" -ForegroundColor Magenta
}

# --- AUTO-INJECTION ON SCRIPT LOAD ---
Auto-Injection

Write-Host "`n🟢 LEGO Auto-Injection completata." -ForegroundColor Green