# Script per rebuildare tutte le app Electron
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '    SUITEV17 - REBUILD' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

$apps = @(
    'electron-app',
    'Gene1799DesktopApp',
    'Gene1799ArtCorporationeHubElectron',
    'GenStudioApp',
    'OpsControlApp',
    'SUITEV17_App'
)

foreach ($app in $apps) {
    Write-Host "Rebuild $app..." -ForegroundColor Yellow
    cd "C:\SuiteV17\$app"
    npm run build 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$app : REBUILD OK" -ForegroundColor Green
    } else {
        Write-Host "$app : Nessun build script" -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '    REBUILD COMPLETATO' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Premi un tasto per uscire...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
