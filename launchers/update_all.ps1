# Script per aggiornare tutte le dipendenze
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '    SUITEV17 - AGGIORNAMENTO' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

$apps = @(
    'electron-app',
    'Gene1799DesktopApp',
    'Gene1799ArtCorporationeHubElectron',
    'GenStudioApp',
    'OpsControlApp',
    'SUITEV17_App',
    'AIHub'
)

foreach ($app in $apps) {
    Write-Host "Aggiornando $app..." -ForegroundColor Yellow
    cd "C:\SuiteV17\$app"
    npm update
    Write-Host "$app aggiornato!" -ForegroundColor Green
    Write-Host ''
}

Write-Host 'Aggiornando root...'
cd C:\SuiteV17
npm update
Write-Host 'Root aggiornato!' -ForegroundColor Green

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '    AGGIORNAMENTO COMPLETATO' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Premi un tasto per uscire...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
