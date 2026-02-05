# GENE1799 Supreme Monitor v9.2 - FIXED VERSION
# Usage: .\GENE1799-SUPREME-MONITOR.ps1

$ErrorActionPreference = "SilentlyContinue"

$serviceUrl = "https://gene1799-backend.onrender.com"
$localUrl = "http://localhost:10000"
$maxAttempts = 40
$attempt = 0

Write-Host @"

╔════════════════════════════════════════════════════════════════════╗
║         GENE1799 SUPREME MONITOR v9.2 - PRODUCTION READY         ║
╚════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "🔄 Production: $serviceUrl" -ForegroundColor White
Write-Host "🔄 Local:      $localUrl" -ForegroundColor White
Write-Host ""

# Test endpoints
$endpoints = @(
    @{ name='Health Check'; path='/api/health'; method='GET' },
    @{ name='IP Verification'; path='/api/ip-check'; method='GET' },
    @{ name='Agents List'; path='/api/agents?limit=10'; method='GET' },
    @{ name='Metrics'; path='/api/metrics'; method='GET' },
    @{ name='IP Statistics'; path='/api/ip-stats'; method='GET' }
)

$report = @{
    startTime = Get-Date
    production = @{ passed=0; failed=0; tests=@() }
    local = @{ passed=0; failed=0; tests=@() }
}

function Test-Endpoint {
    param($baseUrl, $endpoint, $reportSection)
    
    try {
        $uri = "$baseUrl$($endpoint.path)"
        $params = @{
            Uri = $uri
            TimeoutSec = 10
            Method = $endpoint.method
        }
        
        $response = Invoke-RestMethod @params
        
        $reportSection.passed++
        $reportSection.tests += @{
            endpoint = $endpoint.name
            status = 'PASS'
            timestamp = (Get-Date).ToString('HH:mm:ss')
        }
        
        Write-Host "  ✅ $($endpoint.name)" -ForegroundColor Green
        return $true
        
    } catch {
        $reportSection.failed++
        $reportSection.tests += @{
            endpoint = $endpoint.name
            status = 'FAIL'
            error = $_.Exception.Message.Substring(0, [Math]::Min(50, $_.Exception.Message.Length))
            timestamp = (Get-Date).ToString('HH:mm:ss')
        }
        
        Write-Host "  ❌ $($endpoint.name): $($_.Exception.Message.Substring(0, 40))..." -ForegroundColor Red
        return $false
    }
}

# Main monitoring loop
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "TESTING PRODUCTION SERVER" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

while ($attempt -lt $maxAttempts) {
    $attempt++
    $pct = [math]::Round(($attempt / $maxAttempts) * 100)
    
    Write-Progress -Activity "GENE1799 Production Monitor" -Status "Attempt $attempt/$maxAttempts" -PercentComplete $pct
    
    Write-Host "[$attempt/$maxAttempts] Testing..." -ForegroundColor Cyan
    
    $allPassed = $true
    foreach ($endpoint in $endpoints) {
        $result = Test-Endpoint $serviceUrl $endpoint $report.production
        if (-not $result) { $allPassed = $false }
        Start-Sleep -Milliseconds 200
    }
    
    if ($allPassed) {
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        Write-Host "✅ PRODUCTION SERVER LIVE!" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        Write-Host ""
        Write-Host "🌐 URL: $serviceUrl" -ForegroundColor Cyan
        Write-Host "📊 Tests: $($report.production.passed)/$($endpoints.Count) passed" -ForegroundColor Green
        Write-Host "⏱️  Time: $([math]::Round(((Get-Date) - $report.startTime).TotalSeconds, 1))s" -ForegroundColor White
        
        Write-Progress -Activity "GENE1799 Production Monitor" -Completed
        break
    }
    
    if ($attempt -lt $maxAttempts) {
        Write-Host "  ⏳ Retrying in 15s..." -ForegroundColor DarkGray
        Write-Host ""
        Start-Sleep -Seconds 15
    }
}

Write-Progress -Activity "GENE1799 Production Monitor" -Completed

# Test local server
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "TESTING LOCAL SERVER" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

foreach ($endpoint in $endpoints) {
    Test-Endpoint $localUrl $endpoint $report.local | Out-Null
    Start-Sleep -Milliseconds 200
}

# Final report
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "FINAL REPORT" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "PRODUCTION:" -ForegroundColor Cyan
Write-Host "  Passed: $($report.production.passed)/$($endpoints.Count)" -ForegroundColor $(if($report.production.passed -eq $endpoints.Count){"Green"}else{"Yellow"})
Write-Host "  Failed: $($report.production.failed)" -ForegroundColor $(if($report.production.failed -eq 0){"Green"}else{"Red"})

Write-Host ""
Write-Host "LOCAL:" -ForegroundColor Cyan
Write-Host "  Passed: $($report.local.passed)/$($endpoints.Count)" -ForegroundColor $(if($report.local.passed -eq $endpoints.Count){"Green"}else{"Yellow"})
Write-Host "  Failed: $($report.local.failed)" -ForegroundColor $(if($report.local.failed -eq 0){"Green"}else{"Red"})

Write-Host ""
Write-Host "⏱️  Total Time: $([math]::Round(((Get-Date) - $report.startTime).TotalSeconds, 1))s" -ForegroundColor White

# Save report
$reportFile = "GENE1799-Monitor-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json -Depth 10 | Out-File $reportFile -Encoding UTF8

Write-Host "📄 Report saved: $reportFile" -ForegroundColor Cyan

# Open browser if production is live
if ($report.production.passed -eq $endpoints.Count) {
    Write-Host ""
    Write-Host "🌐 Opening production in browser..." -ForegroundColor Yellow
    Start-Process "$serviceUrl/api/health"
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "GENE1799 ART CORPORATIONE © 2026" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
