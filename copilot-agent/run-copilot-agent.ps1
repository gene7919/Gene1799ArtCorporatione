param(
    [string]$Mode = "full",
    [string]$CancerType = "Neuroblastoma"
)

$ScriptDir = "C:\Users\gene1\Gene1799ArtCorporatione\drug-discovery\copilot-agent"
Set-Location $ScriptDir

Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Gene1799 Copilot Agent Manager              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

switch ($Mode) {
    "full" {
        Write-Host "🚀 Esecuzione pipeline completa..." -ForegroundColor Green
        node copilot-drug-discovery.js
    }
    "analyze" {
        Write-Host "🔬 Modalità analisi..." -ForegroundColor Yellow
        node copilot-drug-discovery.js --mode analyze
    }
    "generate" {
        Write-Host "🆕 Modalità generazione..." -ForegroundColor Yellow
        node copilot-drug-discovery.js --mode generate
    }
    default {
        Write-Host "❌ Modalità non riconosciuta" -ForegroundColor Red
    }
}
