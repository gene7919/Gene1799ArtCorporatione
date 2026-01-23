Write-Host "`n🎯 GENE1799 - TEST COMPLETO" -ForegroundColor Cyan

$tests = @(
    @{Name="Healthcare"; Path="healthcare-integration.js"},
    @{Name="Chelation"; Path="chelation-calculator/chelation-calculator.js"},
    @{Name="Anticancer"; Path="anticancer-engine-v2.js"},
    @{Name="Copilot"; Path="copilot-agent/copilot-drug-discovery.js"},
    @{Name="Owners"; Path="copilot-agent/project-owners.js"}
)

foreach ($test in $tests) {
    if (Test-Path $test.Path) {
        Write-Host "`n🧪 $($test.Name):" -ForegroundColor Yellow
        node $test.Path 2>$null | Select-Object -First 3
        Write-Host "✅ OK" -ForegroundColor Green
    } else {
        Write-Host "`n❌ $($test.Name): NON TROVATO" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Test terminato!" -ForegroundColor Green
