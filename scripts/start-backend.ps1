$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\signer-core"

if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    throw "Maven non trovato nel PATH."
}

mvn spring-boot:run
