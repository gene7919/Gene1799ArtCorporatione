$ErrorActionPreference = "Stop"

Write-Host "Build backend..."
Set-Location "$PSScriptRoot\..\signer-core"
mvn clean package

Write-Host "Build electron..."
Set-Location "$PSScriptRoot\..\electron-app"

if (-not (Test-Path ".\node_modules")) {
    npm install
}

Write-Host "Packaging Electron non ancora configurato in questo scaffold."
