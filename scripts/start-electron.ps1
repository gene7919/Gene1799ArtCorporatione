$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\electron-app"

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw "npm non trovato nel PATH."
}

if (-not (Test-Path ".\node_modules")) {
    npm install
}

npm start
