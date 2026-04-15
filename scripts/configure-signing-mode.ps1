param(
    [ValidateSet("MSCAPI","PKCS11","PKCS12")]
    [string]$Mode = "MSCAPI",
    [string]$ProjectRoot = "C:\Gene1799LegalSign",
    [string]$Pkcs11LibraryPath = "",
    [int]$Pkcs11SlotId = 0,
    [string]$Pkcs12Path = ""
)

$ErrorActionPreference = "Stop"
$configFile = "$ProjectRoot\signer-core\src\main\resources\application.yml"

if (-not (Test-Path $configFile)) {
    throw "application.yml non trovato: $configFile"
}

$content = Get-Content $configFile -Raw
$content = [regex]::Replace($content, 'mode:\s+\w+', "mode: $Mode")
$content = [regex]::Replace($content, 'pkcs11LibraryPath:\s+".*"', "pkcs11LibraryPath: `"$Pkcs11LibraryPath`"")
$content = [regex]::Replace($content, 'pkcs11SlotId:\s+\d+', "pkcs11SlotId: $Pkcs11SlotId")
$content = [regex]::Replace($content, 'pkcs12Path:\s+".*"', "pkcs12Path: `"$Pkcs12Path`"")

Set-Content -Path $configFile -Value $content -Encoding UTF8
Write-Host "Configurazione aggiornata in $configFile"
