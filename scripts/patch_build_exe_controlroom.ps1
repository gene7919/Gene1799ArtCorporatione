$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " BUILD EXE // SUITE V17 CONTROL ROOM " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$AppDir = "C:\SuiteV17\ElectronApp"
$PackagePath = Join-Path $AppDir "package.json"

if (!(Test-Path $PackagePath)) {
    throw "package.json non trovato in $PackagePath"
}

Set-Location $AppDir

Write-Host "Installazione electron-builder..." -ForegroundColor Yellow
npm install electron-builder --save-dev | Out-Host

$package = Get-Content $PackagePath -Raw | ConvertFrom-Json

if (-not $package.scripts) {
    $package | Add-Member -MemberType NoteProperty -Name scripts -Value ([pscustomobject]@{})
}

$buildConfig = [pscustomobject]@{
    appId = "com.suitev17.controlroom"
    productName = "SuiteV17 Control Room"
    directories = [pscustomobject]@{
        output = "dist"
    }
    files = @(
        "**/*",
        "!dist/**",
        "!node_modules/.cache/**"
    )
    win = [pscustomobject]@{
        target = @("nsis")
    }
    nsis = [pscustomobject]@{
        oneClick = $false
        perMachine = $false
        allowToChangeInstallationDirectory = $true
    }
}

if ($package.PSObject.Properties.Name -contains "build") {
    $package.build = $buildConfig
} else {
    $package | Add-Member -MemberType NoteProperty -Name build -Value $buildConfig
}

if ($package.scripts.PSObject.Properties.Name -contains "build") {
    $package.scripts.build = "electron-builder"
} else {
    $package.scripts | Add-Member -MemberType NoteProperty -Name build -Value "electron-builder"
}

$package | ConvertTo-Json -Depth 20 | Set-Content $PackagePath -Encoding UTF8

Write-Host "Configurazione build aggiunta." -ForegroundColor Green

Write-Host "Avvio build..." -ForegroundColor Cyan
npm run build | Out-Host

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " BUILD COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Output previsto in: C:\SuiteV17\ElectronApp\dist"