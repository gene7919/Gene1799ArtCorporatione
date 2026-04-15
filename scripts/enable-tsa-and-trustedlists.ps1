param(
    [string]$ProjectRoot = "C:\Gene1799LegalSign",
    [string]$TsaUrl = "",
    [string]$OjKeystorePath = "",
    [string]$OjKeystorePassword = ""
)

$ErrorActionPreference = "Stop"
$configFile = "$ProjectRoot\signer-core\src\main\resources\application.yml"

if (-not (Test-Path $configFile)) {
    throw "application.yml non trovato: $configFile"
}

$content = Get-Content $configFile -Raw
$content = [regex]::Replace($content, 'enabled:\s+false\s*\n\s*url:', "enabled: true`n    url:")
$content = [regex]::Replace($content, 'url:\s+".*"', "url: `"$TsaUrl`"", 1)
$content = [regex]::Replace($content, 'trustedLists:\s*\n\s*enabled:\s+false', "trustedLists:`n    enabled: true")
$content = [regex]::Replace($content, 'ojKeystorePath:\s+".*"', "ojKeystorePath: `"$OjKeystorePath`"")
$content = [regex]::Replace($content, 'ojKeystorePassword:\s+".*"', "ojKeystorePassword: `"$OjKeystorePassword`"")

Set-Content -Path $configFile -Value $content -Encoding UTF8
Write-Host "TSA e Trusted Lists abilitate in $configFile"
