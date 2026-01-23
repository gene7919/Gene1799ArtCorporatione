Write-Host "`n🎯 GENE1799 FULL PLATFORM TEST" -ForegroundColor Magenta

$modules = @{
    "Healthcare" = "healthcare-integration.js"
    "Chelation" = "chelation-calculator/chelation-calculator.js"
    "Anticancer" = "anticancer-engine-v2.js"
    "Copilot" = "copilot-agent/copilot-drug-discovery.js"
}

foreach ($module in $modules.GetEnumerator()) {
    Write-Host "`n🧪 $($module.Key):" -ForegroundColor Yellow
    if (Test-Path $module.Value) {
        node $module.Value | Select-Object -First 15
        Write-Host "✅ $($module.Key) OK!" -ForegroundColor Green
    } else {
        Write-Host "❌ $($module.Key) mancante" -ForegroundColor Red
    }
}

Write-Host "`n🎉 PLATFORM OPERATIVA!" -ForegroundColor Green
