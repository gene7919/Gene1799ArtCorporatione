param(
    [string]$ProjectRoot = "C:\Gene1799LegalSign"
)

$ErrorActionPreference = "Continue"

Write-Host "== Gene1799 Legal Sign Doctor ==" -ForegroundColor Cyan

function Test-Cmd($name) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "[OK] comando trovato: $name -> $($cmd.Source)" -ForegroundColor Green
        return $true
    }
    Write-Host "[NO] comando mancante: $name" -ForegroundColor Red
    return $false
}

Test-Cmd "java" | Out-Null
Test-Cmd "mvn" | Out-Null
Test-Cmd "node" | Out-Null
Test-Cmd "npm" | Out-Null

if (Test-Path "$ProjectRoot\signer-core\src\main\resources\application.yml") {
    Write-Host "[OK] application.yml trovato" -ForegroundColor Green
} else {
    Write-Host "[NO] application.yml mancante" -ForegroundColor Red
}

if (Test-Path "$ProjectRoot\shared\logs") {
    Write-Host "[OK] cartella log trovata" -ForegroundColor Green
}

$port8090 = Get-NetTCPConnection -LocalPort 8090 -ErrorAction SilentlyContinue
if ($port8090) {
    Write-Host "[INFO] porta 8090 occupata" -ForegroundColor Yellow
} else {
    Write-Host "[OK] porta 8090 libera" -ForegroundColor Green
}

$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($port3000) {
    Write-Host "[INFO] porta 3000 occupata" -ForegroundColor Yellow
} else {
    Write-Host "[OK] porta 3000 libera" -ForegroundColor Green
}

Write-Host ""
Write-Host "Controlli manuali da fare:" -ForegroundColor Cyan
Write-Host "1. Verifica che il certificato usato sia QUALIFICATO."
Write-Host "2. Verifica che il dispositivo/servizio di firma sia QSCD o firma remota qualificata."
Write-Host "3. Verifica che il prestatore risulti nella Trusted List / elenco AgID."
Write-Host "4. Se usi PKCS11, conferma il percorso esatto della DLL."
Write-Host "5. Se usi TSA, testa l'URL e le credenziali."
