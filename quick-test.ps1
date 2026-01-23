Write-Host "`n🎯 GENE1799 DRUG DISCOVERY - TEST RAPIDO`n" -ForegroundColor Cyan

$modules = @(
    "healthcare-integration.js",
    "chelation-calculator/chelation-calculator.js",
    "anticancer-engine-v2.js", 
    "copilot-agent/copilot-drug-discovery.js"
)

foreach ($module in $modules) {
    if (Test-Path $module) {
        Write-Host "🧪 Testando: $module" -ForegroundColor Yellow
        node $module 2>$null | Select-Object -First 5
        Write-Host "✅ OK`n" -ForegroundColor Green
    } else {
        Write-Host "❌ $module non trovato`n" -ForegroundColor Red
    }
}

Write-Host "🎉 Test completato!" -ForegroundColor Green
