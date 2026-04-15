# Script per pulire cache e file temporanei
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '    SUITEV17 - PULIZIA' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

Write-Host 'Pulizia cache npm...' -ForegroundColor Yellow
npm cache clean --force
Write-Host 'Cache npm pulita!' -ForegroundColor Green

Write-Host ''
Write-Host 'Pulizia cache Python...' -ForegroundColor Yellow
pip cache purge 2>$null
Write-Host 'Cache Python pulita!' -ForegroundColor Green

Write-Host ''
Write-Host 'Pulizia cartelle temporanee...' -ForegroundColor Yellow
$tempFolders = @(
    'C:\SuiteV17\tmp',
    'C:\SuiteV17\logs',
    'C:\SuiteV17\output'
)

foreach ($folder in $tempFolders) {
    if (Test-Path $folder) {
        Remove-Item "$folder\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Pulito: $folder" -ForegroundColor Green
    }
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '    PULIZIA COMPLETATA' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Premi un tasto per uscire...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
